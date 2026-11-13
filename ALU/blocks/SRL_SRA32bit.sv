`timescale 1ns/1ps

module SRL_SRA32bit (
    input wire [31:0] a,
    input wire [4:0] shamt,
    input wire variant,
    output wire [31:0] res
);

    wire [31:0] stage1, stage2, stage3, stage4;
    wire fill_bit;

    // choosing SRL or SRA
    assign fill_bit = variant & a[31];

    // barrel shifter
    assign stage1 = shamt[0] ? {fill_bit, a[31:1]} : a;

    assign stage2 = shamt[1] ? {{2{fill_bit}}, stage1[31:2]} : stage1;

    assign stage3 = shamt[2] ? {{4{fill_bit}}, stage2[31:4]} : stage2;

    assign stage4 = shamt[3] ? {{8{fill_bit}}, stage3[31:8]} : stage3;

    assign res = shamt[4] ? {{16{fill_bit}}, stage4[31:16]} : stage4;

endmodule
