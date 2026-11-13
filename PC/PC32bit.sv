`timescale 1ns/1ps

module PC32bit (
    input wire [31:0] pc_in,
    input wire enable,
    input wire reset,
    input wire clk,
    output wire [31:0] pc_out
);

    wire [31:0] d;
    reg [31:0] q;

    assign d = reset ? 32'b0 : (enable ? pc_in : q);

    always @(posedge clk)
        q <= d;

    assign pc_out = q;

endmodule
