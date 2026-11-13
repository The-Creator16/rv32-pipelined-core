# 32-bit program counter

[PC32bit.sv](PC32bit.sv) stores the processor's current 32-bit instruction address. It loads `pc_in` on a positive clock edge when `enable` is high. An active-high synchronous `reset` sets the stored address to zero and has priority over `enable`.

## Interface

| Port | Direction | Width | Meaning |
|---|---|---|---|
| pc_in | Input | 32 | Next address supplied by the datapath |
| enable | Input | 1 | Allow loading the next address |
| reset | Input | 1 | Clear the address on the next positive clock edge |
| clk | Input | 1 | Clock |
| pc_out | Output | 32 | Currently stored address |

## Register behavior

| reset | enable | Value after the positive edge |
|---|---|---|
| 1 | Either | 0 |
| 0 | 1 | pc_in |
| 0 | 0 | Previous pc_out |

The register is described with a 32-bit flip-flop bank `q` and combinational next-state signal `d`.

```systemverilog
assign d = reset ? 32'b0 : (enable ? pc_in : q);

always @(posedge clk)
    q <= d;

assign pc_out = q;
```

The datapath computes the next address outside this module. For example, it can select `pc_out + 4`, a branch target, or a jump target and supply the selected value to `pc_in`. A pipeline stall can hold the fetch address by clearing `enable`. Instruction alignment and the reset vector are decisions of the surrounding processor. This module accepts any 32-bit input and resets to address zero.

## Files and generated output

| Path relative to the project root | Purpose |
|---|---|
| PC/PC32bit.sv | Register and next-state selection |
| PC/tb/PC32bit_tb.sv | Self-checking simulation |
| PC/Makefile | PC build, test and synthesis targets |
| mk/simulation.mk | Shared ALU and PC simulation rules |
| build/obj/PC/PC32bit.vvp | Compiled simulation program |
| build/vcd/PC/PC32bit.vcd | Optional waveform |

## Build and test

Simulation requires GNU Make and Icarus Verilog (`iverilog` and `vvp`). Synthesis requires Yosys. GTKWave can display the generated waveform.

Run these commands from the project root.

| Command | Result |
|---|---|
| `make build-PC` | Compile the PC testbench |
| `make test-PC` | Run the PC test with 200,000 random cycles |
| `make test-PC32bit RANDOM_TESTS=1000` | Run directed checks and 1,000 random cycles |
| `make wave-PC32bit WAVE_TESTS=16` | Record reset checks, directed cases and 16 random cycles |
| `gtkwave build/vcd/PC/PC32bit.vcd` | Open the waveform |
| `make synth-PC` | Synthesize PC and check for structural errors and latches |
| `make clean-PC` | Remove only PC simulation programs and waveforms |
| `make -j7 test` | Run all implemented block tests |
| `make clean` | Remove all generated output |

From inside the PC directory, use `make build`, `make test`, `make wave-PC32bit`, `make synth`, or `make clean`. The root Makefile delegates to the block Makefiles. Command-line settings such as `RANDOM_TESTS=1000` propagate to them.

Waveforms are enabled by the testbench's `+waves` argument. The Makefile runs simulation from the project root so that waveform paths are consistent from either directory. A test command keeps any waveform from an earlier wave command on disk.

## Verification

The testbench drives inputs on negative clock edges and checks the registered result 1 ns after positive edges, allowing the nonblocking assignment to settle. The test clock has a 4 ns period.

The checks cover initial reset with both enable values, loading boundary patterns, holding a nonzero address over several cycles, reset priority after loading a nonzero address, holding after reset, and 200,000 random cycles by default. Random inputs exercise both enable values and occasionally assert reset. Each directed and random cycle also checks that changing the inputs at the negative edge leaves the output unchanged until the positive edge.