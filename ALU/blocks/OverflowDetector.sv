`timescale 1ns/1ps

module OverflowDetector (
    input wire a_sign,
    input wire b_sign,
    input wire res_sign,
    output wire overflow_add,
    output wire overflow_sub
);

    wire xor_ab;
    wire xor_ares;

    assign xor_ab = a_sign ^ b_sign;
    assign xor_ares = a_sign ^ res_sign;
    // when operands have the same sign and the result has the opposite sign
    assign overflow_add = (~xor_ab) & xor_ares;
    // when operands have opposite signs and the result sign differs from a
    assign overflow_sub = xor_ab & xor_ares;

endmodule
