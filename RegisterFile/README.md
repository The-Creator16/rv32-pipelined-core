# 32-bit register file

[RegFile32bit.sv](RegFile32bit.sv) implements two independent combinational read ports and one falling-edge write port. Each address is five bits wide. Register x0 always reads as zero. Registers x1 through x31 each store one 32-bit word and have no reset.

| Signal | Behavior |
|---|---|
| read_addr_0, read_addr_1 | Select one register independently for each read port |
| read_data_0, read_data_1 | Return the selected words, including when both ports select the same register |
| write_addr, write_data | Select the destination register and its next 32-bit value |
| write_enable, clk | Commit the write on the falling edge when enabled |

The generate loop builds one write-enable decoder output and a data/hold mux for each writable register. An enabled write to x0 selects none of them. Reading a register during a write gives its old value before the falling edge and its updated value after the nonblocking assignment settles. A writable register starts unknown in simulation until written.

## Build and test

| Command from project root | Result |
|---|---|
| `make test-RegisterFile` | Run 1,000 randomized register-bank passes and directed checks |
| `make test-RegFile32bit RANDOM_TESTS=10` | Run ten passes plus directed checks |
| `make wave-RegisterFile` | Write build/vcd/RegisterFile/RegFile32bit.vcd |
| `make synth-RegisterFile` | Synthesize the register file with Yosys |

From this directory use `make build`, `make test`, `make wave`, `make synth` or `make clean`. The [testbench](tb/RegFile32bit_tb.sv) writes all 31 writable registers, reads both ports, tests disabled writes and x0, and checks a simultaneous read of the destination before and after the write edge.
