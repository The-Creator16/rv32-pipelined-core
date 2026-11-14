# Pipeline performance microbenchmarks

Four deterministic RV32I programs run on the repository's **unchanged CPU RTL**.
The suite measures architectural instruction throughput, load-use stalls,
forwarding, and the existing static always-taken conditional branch predictor.
It does not compare alternative hardware implementations.

## Reproduce

Requirements: Python 3 (standard library only), Icarus Verilog and `vvp`.
The checked-in results were obtained with Icarus Verilog 12.0.
From the repository root:

```sh
make performance
# Optional waveforms:
make performance-wave
# Equivalent direct invocation:
python3 Performance/run.py
```

`IVERILOG` and `VVP` environment variables can override tool commands.
The runner assembles the four `.S` sources, produces an independent sequential
reference trace, compiles the SystemVerilog testbench, and starts a fresh CPU
simulation for each program. No RISC-V cross-compiler or pip package is needed.
The included assembler is intentionally limited to ADDI, ADD, LW, SW, BEQ,
BNE, JAL and JALR; it is not a general RISC-V toolchain.

## Measured results

| Program | Retired instructions | Cycles | CPI | Load-use stall cycles | Conditional branches | Taken | Mispredictions | JAL/JALR |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 01_independent | 33 | 37 | 1.121212 | 0 | 0 | 0 | 0 | 0 |
| 02_forwarding | 33 | 37 | 1.121212 | 0 | 0 | 0 | 0 | 0 |
| 03_load_use | 49 | 61 | 1.244898 | 8 | 0 | 0 | 0 | 0 |
| 04_branches | 37 | 64 | 1.729730 | 0 | 14 | 9 | 5 | 2 |

These are small diagnostic workloads, not representative application benchmarks.
The first two have equal instruction counts but compute different values; their
comparison isolates dependency handling, not equivalent-program speedup.

### 1. Independent arithmetic

32 ADDI instructions read x0; no instruction consumes a preceding result.
An additional `addi x31, x0, 123` is the completion marker.
There are no hazard/control penalties: **33 + 4 = 37 cycles**.
CPI is above one solely because this short stream includes pipeline fill/drain.

### 2. RAW dependencies and forwarding

Eight groups execute:

```asm
addi x1, x0, K
addi x2, x1, 1
add  x3, x1, x2
add  x4, x3, x2
```

The test exercises both forwarding sources and both operands, including MEM
priority when applicable. Observed selected forwarding counts are **24 MEM
operands and 16 WB operands**. These are operand events, not cycles: two operands
may be forwarded in the same cycle. No stalls are required, so the total remains
**33 + 4 = 37 cycles** despite the RAW dependencies.

### 3. Load-use hazards and instruction scheduling

Each of eight groups contains:

```asm
lw   x1, OFFSET(x0)
addi x2, x1, 1          # Immediate consumer: one stall
lw   x3, OFFSET(x0)
addi x4, x0, K          # Useful independent work, not a NOP
add  x5, x3, x4         # Scheduled consumer: no load-use stall
sw   x5, OUTPUT(x0)     # Store-data forwarding
```

There are 16 loads but only eight load-use stalls. The second load in each group
has an independent instruction before its consumer. The per-cycle traces place
all eight stalls at the first load/consumer pair of each group.
The total is **49 + 4 + 8 = 61 cycles**. All eight stores are checked against the
reference model, including their order, addresses and data.

### 4. Static prediction and redirects

The backward BNE loop runs eight times: seven taken outcomes and one not taken.
Four forward BEQ instructions are not taken; two forward BEQ instructions are
taken. Thus **14 conditional branches = 9 taken + 5 not taken**. JAL and JALR are
counted separately, not included in prediction accuracy.

The actual RTL predicts every conditional branch taken in **Decode**, not Fetch:

- Each prediction flushes IF/ID and introduces one bubble, even when correct
- A not-taken outcome redirects in Execute, adding one further bubble
- Each JAL/JALR resolves in Execute and costs two bubbles

Conditional prediction accuracy is **9/14 = 64.29%**. The loop alone achieves
7/8 = 87.5%; the forward-not-taken group achieves 0/4; forward-taken branches
achieve 2/2. The predictor is static and does not learn from previous outcomes.

The resulting accounting is **37 + 4 + 14 + 5 + 2*2 = 64 cycles**.
Wrong-path stores target distinct sentinel locations. The test checks that they
never occur and that the full data memory matches the architectural result.
The valid result store writes 8 to byte address 256.

## Measurement convention

- Reset cycles are excluded. Cycle 1 is the first non-reset rising edge, when
  the first fetched instruction enters IF/ID
- An instruction is counted at the rising edge ending its WB slot, using the
  old stage values before nonblocking assignments. The register file writes on
  the preceding falling edge; that write is checked too
- The endpoint is the completion marker's WB slot, not its Decode/Execute stage
- This inclusive pipeline-slot convention gives **N + 4** for a hazard-free
  five-stage stream. It is not a measurement of elapsed physical nanoseconds
- The completion marker is a real instruction and is included in N and CPI
- Stores, branches and jumps count as instructions even when RegWrite is zero
- The CPU has no retirement/valid port. Testbench-only shadow valid bits and
  PC/instruction tags follow the real stall/flush controls through D/E/M/W
- Injected bubbles and wrong-path instructions do not count as retired. Real
  NOPs would count. Therefore RegWrite or an instruction-value comparison is
  not used as the retirement counter
- The unit tests use deterministic, initialized memory and avoid uninitialized
  register reads; no CPU register initialization or RTL modification is added

For these four streams, verified both analytically and in simulation:

**cycles = retired + 4 + load-use stalls + conditional branches + mispredictions + 2*jumps**

Equivalently, branch cost is 1 per taken outcome and 2 per not-taken outcome.
Control penalties, load-use stalls and fill/drain overhead are separate terms.
This identity is specific to the measured streams and present pipeline; do not
assume it holds unchanged for arbitrary overlaps, other predictors or memory
latencies.

### Why raw flush counters are not lost-cycle counters

| Program | IF/ID flush cycles | ID/EX flush cycles | Redirect events |
| --- | ---: | ---: | ---: |
| Independent | 0 | 0 | 0 |
| Forwarding | 0 | 0 | 0 |
| Load-use | 0 | 8 | 0 |
| Branches | 21 | 7 | 7 |

In the branch test, IF/ID flushes occur for 14 predictions and 7 redirects
(5 conditional misses plus 2 jumps). ID/EX is flushed for those 7 redirects.
The two flush signals can assert together; a flushed stage may already hold a
bubble. **Do not sum these counters to estimate extra cycles**. Branch/jump
penalties total 23 cycles, not 21 + 7. There are zero load-use stall cycles in
that program despite its large control-flow overhead.

## Correctness and evidence

`generate.py` assembles sources, then independently decodes the machine words
in a sequential interpreter. It does not simulate pipeline timing. At runtime,
`tb/Performance_tb.sv` verifies:

1. Every retired PC and instruction against the expected dynamic trace
2. Each architectural register result, including the actual RF value
3. Every memory store's order, address and data at MEM
4. All 1024 data-memory words at completion, including wrong-path sentinels
5. Completion, timeout, x0, instruction/store counts and cycle accounting

`run.py` also checks event totals against the reference model and fixed
analytical cycle expectations. A mismatch produces a failing process exit code.

- `programs/*.S`: readable input programs
- `programs/*.hex`: complete memory images and generated reference data
- `results/summary.csv`: machine-readable aggregate results
- `results/*.trace.csv`: per-cycle PCs, validity, stalls and control events
- `results/run.log`: simulation output
- `results/provenance.json`: simulator version and SHA-256 of all CPU RTL inputs

The trace columns are sampled before each rising-edge DUT update; interpret
`valid_*` before using a stage PC. Detailed forwarding counters count selected,
actually used source operands and respect MEM-over-WB priority.

This measures an RTL pipeline with the repository's combinational memory model.
There are no caches, variable-latency DRAM, OS effects or physical timing delays.
A 10 ns testbench clock only schedules simulation events; it is not evidence of
100 MHz timing closure. These tests are not a complete ISA conformance suite.
