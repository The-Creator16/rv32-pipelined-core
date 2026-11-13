`timescale 1ns/1ps

module InstructionAdder (
    input wire [31:0] instr_addr,
    output wire [31:0] instr_addr_plus4
);
    genvar k;
    wire [31:3] carry;

    assign instr_addr_plus4[1:0] = instr_addr[1:0];
    assign instr_addr_plus4[2] = ~instr_addr[2];

    generate
        for(k=3; k<32; k=k+1) begin : gen_addr
            assign carry[k] = &instr_addr[k-1:2];
            assign instr_addr_plus4[k] = instr_addr[k] ^ carry[k];
        end
    endgenerate

endmodule
