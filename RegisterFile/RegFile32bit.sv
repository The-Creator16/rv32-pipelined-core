`timescale 1ns/1ps

module RegFile32bit (
    input wire [4:0] read_addr_0,
    input wire [4:0] read_addr_1,
    input wire [4:0] write_addr,
    input wire [31:0] write_data,
    input wire clk,
    input wire write_enable,
    output wire [31:0] read_data_0,
    output wire [31:0] read_data_1
);

    genvar k;

    wire [31:1] reg_write_enable;
    wire [31:0] d [31:1];
    wire [31:0] q [31:0];

    assign q[0] = 32'b0;

    generate
        for(k=1; k<32; k=k+1) begin : gen_registers
            reg [31:0] stored_data;
            assign q[k] = stored_data;

            // decode write address and enable
            assign reg_write_enable[k] =
                write_enable && (write_addr == k);

            // select new data or hold current value
            assign d[k] = reg_write_enable[k] ? write_data : q[k];

            always @(negedge clk)
                stored_data <= d[k];
        end
    endgenerate

    assign read_data_0 =
        (read_addr_0 == 5'b0) ? 32'b0 : q[read_addr_0];

    assign read_data_1 =
        (read_addr_1 == 5'b0) ? 32'b0 : q[read_addr_1];

endmodule
