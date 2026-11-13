`timescale 1ns/1ps

module SLL32bit (
    input wire [31:0] a,
    input wire [4:0] shamt,
    output wire [31:0] res
);

    wire [31:0] stage1, stage2, stage3, stage4;

    // barrel shifter
    assign stage1 = shamt[0] ? {a[30:0], 1'b0} : a;

    assign stage2 = shamt[1] ? {stage1[29:0], 2'b0} : stage1;

    assign stage3 = shamt[2] ? {stage2[27:0], 4'b0} : stage2;

    assign stage4 = shamt[3] ? {stage3[23:0], 8'b0} : stage3;

    assign res = shamt[4] ? {stage4[15:0], 16'b0} : stage4;

endmodule
