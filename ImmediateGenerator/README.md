# Immediate generator

[ImmediateGenerator.sv](ImmediateGenerator.sv) implements the block. The three-bit `control` selects fields of the 32-bit `instruction`. The combinational output `immediate` can feed address calculation or the ALU.

## Behavior and verification

| control | Format | Output |
|---|---|---|
| 000 | I | Signed 12-bit immediate |
| 001 | S | Signed 12-bit store offset |
| 010 | B | Signed byte offset from −4096 to 4094, in steps of two |
| 011 | U | Upper 20 bits followed by 12 zeros |
| 100 | J | Signed byte offset from −1048576 to 1048574, in steps of two |
| Other | Reserved | Zero |

The test encodes expected values into instruction fields and randomizes unrelated bits. It covers signed limits and reserved selectors.

## Build and test

| Command from project root | Result |
|---|---|
| `make test-ImmediateGenerator` | Run the [testbench](tb/ImmediateGenerator_tb.sv) |
| `make wave-ImmediateGenerator` | Write build/vcd/ImmediateGenerator/ImmediateGenerator.vcd |
| `make synth-ImmediateGenerator` | Check and synthesize the RTL |

Inside this directory use `make build`, `make test`, `make wave`, `make synth` or `make clean`.
