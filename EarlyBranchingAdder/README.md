# Branch target adder

[EarlyBranchingAdder.sv](EarlyBranchingAdder.sv) implements the block. The combinational output `res` is the low 32 bits of `a + b`. For a conditional branch, supply the address of the branch instruction on `a` and the sign-extended B-format byte offset on `b`. The immediate generator already supplies the low zero bit.

## Behavior and verification

Eight instances of [CLA4bit](../ALU/blocks/CLA4bit.sv) form the sum. Group carry logic supplies the incoming carry for each four-bit block. The test checks boundary operands and random pairs against 32-bit addition.

## Build and test

| Command from project root | Result |
|---|---|
| `make test-EarlyBranchingAdder` | Run the [testbench](tb/EarlyBranchingAdder_tb.sv) |
| `make wave-EarlyBranchingAdder` | Write build/vcd/EarlyBranchingAdder/EarlyBranchingAdder.vcd |
| `make synth-EarlyBranchingAdder` | Check and synthesize the RTL |

Inside this directory use `make build`, `make test`, `make wave`, `make synth` or `make clean`.
