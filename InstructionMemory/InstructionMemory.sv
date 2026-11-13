`timescale 1ns/1ps

module InstructionMemory #(
    parameter PROGRAM_FILE = "InstructionMemory/program.hex"
) (
    input wire [31:0] inst_address,
    output wire [31:0] instruction
);

    reg [31:0] memory [0:1023];

    initial
        $readmemh(PROGRAM_FILE, memory);

    assign instruction = memory[inst_address >> 2];

endmodule
