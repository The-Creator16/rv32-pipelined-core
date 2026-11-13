# Five-stage processor

[CPU32bit](CPU32bit.sv) connects the fetch, decode, execute, memory and writeback stages. Drive `clk` and assert `reset` across a rising edge to restart fetch at address zero and clear the pipeline. Reset inhibits register and memory writes. Stored registers and data memory retain their contents.

| Stage | Operation |
|---|---|
| IF | Fetch the word at the current PC and compute PC + 4 |
| ID | Decode, read operands, form the immediate and predict conditional branches taken |
| EX | Forward operands, execute arithmetic, resolve branch conditions and compute jump targets |
| MEM | Read or update the selected data lanes |
| WB | Select the ALU result, loaded value or return address for the register file |

Pipeline registers update on the rising edge. The register file writes on the falling edge, so decode can see a writeback value before its next rising edge. EX selects the newest available forwarded value. A dependent instruction immediately following a load stalls fetch and decode for one cycle and inserts a bubble in EX.

A taken prediction discards the sequential instruction in fetch. A branch resolved as untaken redirects to its saved PC + 4. Jumps redirect in EX. A redirect flushes both younger entries and takes priority over a younger prediction. JALR clears bit zero of its target.

## Programs and verification

Override `PROGRAM_FILE` and `DATA_FILE` to select memory images relative to the project root. The integrated [test program](tb/pipeline.hex) checks register and store forwarding, a load-use dependency, taken and untaken branches, a jump link and suppression of wrong-path stores. The CPU exposes clock and reset ports.

## Build and test

| Command from the project root | Result |
|---|---|
| `make test-CPU` | Run [the testbench](tb/CPU32bit_tb.sv) |
| `make wave-CPU` | Write build/vcd/CPU/CPU32bit.vcd |
| `make synth-CPU` | Check the CPU design with Yosys |

Inside this directory use `make build`, `make test`, `make wave`, `make synth` or `make clean`.
