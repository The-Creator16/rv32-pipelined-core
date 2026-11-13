`timescale 1ns/1ps

module DataMemory #(
    parameter DATA_FILE = "DataMemory/data.hex"
) (
    input wire [31:0] data_addr,
    input wire [31:0] data_write,
    input wire clk,
    input wire write_enable,
    input wire [1:0] mem_size,
    input wire load_unsigned,
    output reg [31:0] data_read
);

    reg [31:0] memory [0:1023];

    wire address_in_range;
    wire [9:0] word_index;
    wire [4:0] bit_offset;
    wire [31:0] selected_word;
    wire [31:0] shifted_word;
    reg access_valid;

    initial begin
        if (DATA_FILE != "")
            $readmemh(DATA_FILE, memory);
    end

    assign address_in_range = (data_addr < 32'd4096);
    assign word_index = data_addr[11:2];
    assign bit_offset = {data_addr[1:0], 3'b000};
    assign selected_word = memory[word_index];
    assign shifted_word = selected_word >> bit_offset;

    // only naturally aligned accesses are supported.
    always @* begin
        access_valid = 1'b0;
        if (address_in_range) begin
            case (mem_size)
                2'b00: access_valid = 1'b1;
                2'b01: access_valid = (data_addr[0] == 1'b0);
                2'b10: access_valid = (data_addr[1:0] == 2'b00);
                default: access_valid = 1'b0;
            endcase
        end
    end

    always @* begin
        data_read = 32'b0;
        if (!write_enable && access_valid) begin
            case (mem_size)
                2'b00: data_read = load_unsigned
                    ? {24'b0, shifted_word[7:0]}
                    : {{24{shifted_word[7]}}, shifted_word[7:0]};
                2'b01: data_read = load_unsigned
                    ? {16'b0, shifted_word[15:0]}
                    : {{16{shifted_word[15]}}, shifted_word[15:0]};
                2'b10: data_read = selected_word;
                default: data_read = 32'b0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (write_enable && access_valid) begin
            case (mem_size)
                2'b00: memory[word_index][bit_offset +: 8] <= data_write[7:0];
                2'b01: memory[word_index][bit_offset +: 16] <= data_write[15:0];
                2'b10: memory[word_index] <= data_write;
                default: begin end
            endcase
        end
    end

endmodule
