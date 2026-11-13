# Instruction memory

[InstructionMemory.sv](InstructionMemory.sv) is a 4 KiB instruction ROM with 1,024 words of 32 bits. Reading is combinational. Supply the byte address from the PC on `inst_address` and read the word on `instruction`.

| Byte address | Word index |
|---|---|
| 0 | 0 |
| 4 | 1 |
| 4092 | 1023 |

Use aligned addresses from 0 through 4092. The index is the byte address shifted right by two. The block ignores the two low bits and leaves alignment and range checks to the processor.

## Program image

The default `PROGRAM_FILE` is [program.hex](program.hex), loaded by `$readmemh`. Each hexadecimal value initializes one word. The directive `@000003FF` moves the write position to word 1023. Locations omitted from the image start unknown in RTL simulation. Override the parameter to use a different image. Relative image paths are resolved from the simulation working directory, which the Makefile sets to the project root.

## Build and test

| Command from project root | Result |
|---|---|
| `make test-InstructionMemory` | Check the first four words, the last word and repeated reads in a different order |
| `make wave-InstructionMemory` | Write build/vcd/InstructionMemory/InstructionMemory.vcd |
| `make synth-InstructionMemory` | Synthesize the ROM with the bundled image |

From this directory use `make build`, `make test`, `make wave`, `make synth` or `make clean`. The [testbench](tb/InstructionMemory_tb.sv) expects the bundled image.
