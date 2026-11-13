# Instruction address incrementer

[InstructionAdder.sv](InstructionAdder.sv) implements the block. The combinational output `instr_addr_plus4` is `instr_addr + 4` modulo 2³². Bits 1 and 0 pass through and bit 2 inverts. Higher bits toggle when all lower operand bits down to bit 2 are set.

## Behavior and verification

The test propagates a carry across each boundary up to 32-bit wraparound and compares random inputs against addition by four.

## Build and test

| Command from project root | Result |
|---|---|
| `make test-InstructionAdder` | Run the [testbench](tb/InstructionAdder_tb.sv) |
| `make wave-InstructionAdder` | Write build/vcd/InstructionAdder/InstructionAdder.vcd |
| `make synth-InstructionAdder` | Check and synthesize the RTL |

Inside this directory use `make build`, `make test`, `make wave`, `make synth` or `make clean`.
