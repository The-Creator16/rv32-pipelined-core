# Data memory

[DataMemory.sv](DataMemory.sv) implements 4 KiB of little-endian data memory. The address is shared by reads and writes. For bytes, halfwords and words the last valid starting addresses are 4095, 4094 and 4092 respectively.

| mem_size | Width | Alignment |
|---|---|---|
| 00 | Byte | Any byte address |
| 01 | Halfword | Multiple of two |
| 10 | Word | Multiple of four |

Reads are combinational. Byte and halfword loads sign-extend unless `load_unsigned` is high. While `write_enable` is high the output is zero. At the rising clock edge a valid write updates only the selected lanes using the low bits of `data_write`. Invalid sizes, out-of-range and misaligned accesses read zero and suppress writes.

## Behavior and verification

The DATA_FILE parameter selects the initial image. Its default is [data.hex](data.hex), relative to the project root. Unspecified words start unknown in simulation. The test checks the first and last initialized words, checks each byte lane, both extension modes, mixed-width and disabled writes, invalid accesses, and compares all 1,024 final words against a byte-oriented model. A wave run also saves the final contents in build/vcd/DataMemory/data_result.hex.

## Build and test

| Command from project root | Result |
|---|---|
| `make test-DataMemory` | Run the [testbench](tb/DataMemory_tb.sv) |
| `make wave-DataMemory` | Write build/vcd/DataMemory/DataMemory.vcd |
| `make synth-DataMemory` | Check and synthesize the RTL |

Inside this directory use `make build`, `make test`, `make wave`, `make synth` or `make clean`.
