# Control unit

[CU32bit](CU32bit.sv) decodes opcode, funct3 and funct7 combinationally in ID. Unsupported encodings suppress writes and control transfers.

| Instruction group | Decode behavior |
|---|---|
| Register and immediate ALU | Select the operation, variant and second operand |
| LUI, AUIPC | Add the U immediate to zero or the instruction PC |
| Loads and stores | Select address addition, transfer width, sign extension and write enables |
| Conditional branches | Select B immediate and equality, signed or unsigned comparison |
| JAL, JALR | Select the jump base and write PC + 4 to the destination |

The [ALU](../ALU/README.md) and [immediate generator](../ImmediateGenerator/README.md) document their control encodings. The decoder test compares 37 instruction rules against all 131,072 combinations of its input fields in ascending and descending order. Unsupported inputs are checked for side effects.

## Build and test

| Command from the project root | Result |
|---|---|
| `make test-ControlUnit` | Run [the testbench](tb/CU32bit_tb.sv) |
| `make wave-ControlUnit` | Write build/vcd/ControlUnit/CU32bit.vcd |
| `make synth-ControlUnit` | Check the ControlUnit design with Yosys |

Inside this directory use `make build`, `make test`, `make wave`, `make synth` or `make clean`.
