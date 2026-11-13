# 32-bit RISC-V processor

A five-stage SystemVerilog processor implementing 37 RV32I integer instructions. The core supports arithmetic, logic, shifts, comparisons, byte/halfword/word memory access, conditional branches, jumps, LUI and AUIPC. Conditional branches use static taken prediction. Exceptions, system instructions and FENCE are outside the implemented subset.

## Blocks

- [CPU](CPU/README.md)
- [Control unit](ControlUnit/README.md)
- [PC](PC/README.md)
- [InstructionAdder](InstructionAdder/README.md)
- [InstructionMemory](InstructionMemory/README.md)
- [RegisterFile](RegisterFile/README.md)
- [ImmediateGenerator](ImmediateGenerator/README.md)
- [ALU](ALU/README.md)
- [EarlyBranchingAdder](EarlyBranchingAdder/README.md)
- [DataMemory](DataMemory/README.md)

## Build and test

From the project root, run `make -j4 test` with GNU Make and Icarus Verilog. Use `make build` to compile all 15 testbenches, `make synth` to synthesize the nine component blocks and check the integrated CPU hierarchy with Yosys, and `make clean` to remove generated output.

For a single block, use targets such as `make test-DataMemory` or `make wave-DataMemory`. Open the resulting waveform with `gtkwave build/vcd/DataMemory/DataMemory.vcd`. Randomized tests accept `RANDOM_TESTS` and wave runs accept `WAVE_TESTS`. The decoder test and directed memory sweeps always run in full.
