`timescale 1ns/1ps

module CLA4bit (
    input wire [3:0] p,
    input wire [2:0] g,
    input wire carry_in,
    output wire [3:0] res
);

    wire carry1, carry2, carry3;

    assign carry1 = g[0] | (p[0] & carry_in);
    assign carry2 = g[1] | (p[1] & g[0]) | (p[1] & p[0] & carry_in);
    assign carry3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & carry_in);

    assign res[0] = carry_in ^ p[0];
    assign res[1] = carry1 ^ p[1];
    assign res[2] = carry2 ^ p[2];
    assign res[3] = carry3 ^ p[3];

endmodule
