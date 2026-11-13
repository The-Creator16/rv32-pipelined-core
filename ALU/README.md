# 32-bit ALU

[ALU32bit.sv](ALU32bit.sv) is the combinational integer ALU for the processor. It takes two 32-bit operands (`a`, `b`) and produces a 32-bit result (`alu_res`) and two one-bit flags (`equal`, `overflow`).

## Operation encoding

The control unit supplies the project's internal three-bit `alu_control` and one-bit `variant`.

| alu_control | variant | Operation | alu_res |
|---|---|---|---|
| 000 | 0 | ADD | Low 32 bits of a + b |
| 000 | 1 | SUB | Low 32 bits of a − b |
| 001 | 0 | SRL | Right shift with zero fill |
| 001 | 1 | SRA | Right shift with sign fill |
| 010 | Either | AND | Bitwise AND |
| 011 | Either | OR | Bitwise OR |
| 100 | Either | XOR | Bitwise XOR |
| 101 | Either | SLL | Left shift with zero fill |
| 110 | 1 | SLT | 1 if signed a < b, otherwise 0 |
| 111 | 1 | SLTU | 1 if unsigned a < b, otherwise 0 |

All shifts use `b[4:0]`, giving a distance of 0–31. For SLT and SLTU the decoder must set `variant = 1` to select subtraction. The comparison result occupies bit 0. Bits 31 through 1 are zero.

## Datapath

- **Arithmetic.** [CLA32bit](blocks/CLA32bit.sv) computes bit propagate and generate signals in parallel, groups them into eight four-bit blocks, and calculates the carries between groups (carry4, carry8, carry12, ..., carry32). Each [CLA4bit](blocks/CLA4bit.sv) forms four sum bits from its local signals and incoming carry. ADD uses b and a carry-in of zero. SUB uses the complement of b and a carry-in of one.
- **Comparison.** SLT uses the sign of the difference XOR signed subtraction overflow. SLTU uses the inverse of the subtraction carry-out, which indicates a borrow. For example, comparing `0x80000000` with zero gives SLT = 1 and SLTU = 0.
- **Shifts.** [SLL32bit](blocks/SLL32bit.sv) shifts left. [SRL_SRA32bit](blocks/SRL_SRA32bit.sv) shifts right and selects the fill bit. Each path has five combinational stages for distances 1, 2, 4, 8 and 16 (barrel shifter).
- **Flags.** `equal` tests whether all bits of `a ^ b` are zero for every operation. [OverflowDetector](blocks/OverflowDetector.sv) compares operand and result signs. The external `overflow` flag reports signed overflow for ADD and SUB and is zero for other operations. The signed comparison still uses overflow internally.
- **Result selection.** A combinational case statement selects one of the eight result paths.

## Build and test

Run these commands from the project root. Simulation requires GNU Make and Icarus Verilog (`iverilog` and `vvp`). The synthesis and waveform viewing commands use Yosys and GTKWave respectively.

| Command | Result |
|---|---|
| `make build-ALU` | Compile six testbenches into build/obj/ALU |
| `make -j6 test-ALU` | Run all six tests with up to six parallel jobs |
| `make test-ALU32bit` | Test the complete ALU |
| `make test-CLA32bit RANDOM_TESTS=1000` | Run the adder boundary cases and 1,000 random inputs |
| `make wave-ALU32bit WAVE_TESTS=16` | Record boundary cases and 16 random pairs in build/vcd/ALU/ALU32bit.vcd |
| `gtkwave build/vcd/ALU/ALU32bit.vcd` | Inspect signals and internal carries |
| `make synth-ALU` | Synthesize the ALU and check for structural errors and inferred storage |
| `make clean-ALU` | Remove generated files |

The [ALU testbench](tb/ALU32bit_tb.sv) checks all ten operations and both flags for each of 121 boundary pairs and, by default, 200,000 random pairs. Each submodule also has its own testbench in [tb](tb/). CLA4bit exhausts all 512 operand and carry-in combinations. CLA32bit and both shifter tests use directed cases and 200,000 random inputs by default. OverflowDetector covers all eight sign combinations.
