`timescale 1ns/1ps

module ALU32bit (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire variant,
    input wire [2:0] alu_control,
    output reg [31:0] alu_res,
    output wire equal,
    output wire overflow
);

    wire [31:0] b_add_sub;

    wire [31:0] and_res;
    wire [31:0] or_res;
    wire [31:0] xor_res;
    wire [31:0] slt_res;
    wire [31:0] sltu_res;
    wire [31:0] right_shift_res;
    wire [31:0] left_shift_res;

    wire [31:0] add_sub_res;
    wire carry_out;
    wire overflow_add, overflow_sub;
    wire arithmetic_overflow;

    // SLT and SLTU use the subtraction path (variant = 1).
    assign b_add_sub = variant ? (~b) : b;

    CLA32bit add_sub (
        .a(a),
        .b(b_add_sub),
        .carry_in(variant),
        .res(add_sub_res),
        .carry_out(carry_out)
    );

    OverflowDetector overflow_detector (
        .a_sign(a[31]),
        .b_sign(b[31]),
        .res_sign(add_sub_res[31]),
        .overflow_add(overflow_add),
        .overflow_sub(overflow_sub)
    );

    assign arithmetic_overflow = variant ? overflow_sub : overflow_add;

    assign overflow = (alu_control == 3'b000) ? arithmetic_overflow : 1'b0;

    // if signed(a) < signed(b)
    assign slt_res = {31'b0, (add_sub_res[31] ^ arithmetic_overflow)};

    //if unsigned(a) < unsigned(b)
    assign sltu_res = {31'b0, (~carry_out)};

    assign and_res = a & b;

    assign or_res = a | b;

    assign xor_res = a ^ b;

    // is the result of xor == 0 (a = b)
    assign equal = ~|xor_res;

    SRL_SRA32bit shift_right (
        .a(a),
        .shamt(b[4:0]),
        .variant(variant),
        .res(right_shift_res)
    );

    SLL32bit shift_left (
        .a(a),
        .shamt(b[4:0]),
        .res(left_shift_res)
    );

    always @* begin
        case (alu_control)
            3'b000: alu_res = add_sub_res;
            3'b001: alu_res = right_shift_res;
            3'b010: alu_res = and_res;
            3'b011: alu_res = or_res;
            3'b100: alu_res = xor_res;
            3'b101: alu_res = left_shift_res;
            3'b110: alu_res = slt_res;
            3'b111: alu_res = sltu_res;

            default: alu_res = 32'b0;
        endcase
    end

endmodule
