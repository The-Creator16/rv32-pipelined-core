`timescale 1ns/1ps

module tb_RegFile32bit;
    reg [4:0] read_addr_0;
    reg [4:0] read_addr_1;
    reg [4:0] write_addr;
    reg [31:0] write_data;
    reg clk;
    reg write_enable;
    wire [31:0] read_data_0;
    wire [31:0] read_data_1;

    reg [31:0] expected [31:0];

    integer i, j;
    integer errors;
    integer random_tests;

    RegFile32bit dut (
        .read_addr_0(read_addr_0),
        .read_addr_1(read_addr_1),
        .write_addr(write_addr),
        .write_data(write_data),
        .clk(clk),
        .write_enable(write_enable),
        .read_data_0(read_data_0),
        .read_data_1(read_data_1)
    );

    initial begin
        clk = 0;
        forever
            #2 clk = ~clk;
    end

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/RegisterFile/RegFile32bit.vcd");
            $dumpvars(0, tb_RegFile32bit);
        end

        read_addr_0 = 5'b0;
        read_addr_1 = 5'b0;
        write_addr = 5'b0;
        write_data = 32'b0;
        write_enable = 1'b0;

        errors = 0;
        expected[0] = 32'b0;

        if (!$value$plusargs("random_tests=%d", random_tests))
            random_tests = 1000;
        if (random_tests < 0)
            $fatal(1, "random_tests must be nonnegative");

        repeat(random_tests) begin

            for(i=1; i<32; i=i+1) begin
                @(posedge clk);
                write_addr = i;
                write_data = $urandom;
                write_enable = 1;
                expected[i] = write_data;
            end

            @(posedge clk);
            write_enable = 0;

            for(j=0; j<32; j=j+1) begin
                read_addr_0 = j;
                read_addr_1 = 31-j;

                #1;

                if (read_data_0 !== expected[j]) begin
                    errors = errors + 1;
                    $display("read_addr_0=%d, read_data_0=%d, expected=%d", read_addr_0, read_data_0, expected[j]);
                end

                if (read_data_1 !== expected[31-j]) begin
                    errors = errors + 1;
                    $display("read_addr_1=%d, read_data_1=%d, expected=%d", read_addr_1, read_data_1, expected[31-j]);
                end
            end

            // Check that disabled writes preserve all registers
            repeat(8) begin
                @(posedge clk);
                write_enable = 0;
                write_addr = $urandom_range(31, 0);
                write_data = $urandom;

                for(j=0; j<32; j=j+1) begin
                    read_addr_0 = j;
                    read_addr_1 = 31 - j;

                    #1;

                    if (read_data_0 !== expected[j]) begin
                        errors = errors + 1;
                        $display(
                            "HOLD FAIL: read_addr_0=%0d, read_data_0=%h, expected=%h",
                            read_addr_0, read_data_0, expected[j]
                        );
                    end

                    if (read_data_1 !== expected[31-j]) begin
                        errors = errors + 1;
                        $display(
                            "HOLD FAIL: read_addr_1=%0d, read_data_1=%h, expected=%h",
                            read_addr_1, read_data_1, expected[31-j]
                        );
                    end
                end
            end
        end

        // Read the same register on both ports across a write edge.
        @(posedge clk);
        write_addr = 5'd1;
        write_data = 32'hAAAAAAAA;
        write_enable = 1;
        @(posedge clk);
        read_addr_0 = 5'd1;
        read_addr_1 = 5'd1;
        write_data = 32'h55555555;
        #1;
        if (read_data_0 !== 32'hAAAAAAAA || read_data_1 !== 32'hAAAAAAAA)
            $fatal(1, "Register changed before the falling edge");
        @(negedge clk);
        #1;
        if (read_data_0 !== 32'h55555555 || read_data_1 !== 32'h55555555)
            $fatal(1, "Both ports must see the newly written word");

        // check that writes to x0 are ignored
        @(posedge clk);
        write_enable = 1;
        write_addr = 5'b0;
        write_data = 32'hFFFFFFFF;

        @(posedge clk);
        write_enable = 0;
        read_addr_0 = 5'b0;
        read_addr_1 = 5'b0;

        #1;

        if (read_data_0 !== 32'b0) begin
            errors = errors + 1;
            $display("X0 FAIL: read_data_0=%h, expected=0", read_data_0);
        end

        if (read_data_1 !== 32'b0) begin
            errors = errors + 1;
            $display("X0 FAIL: read_data_1=%h, expected=0", read_data_1);
        end


        if (errors == 0)
            $display("PASS");
        else
            $fatal(1, "FAIL: %0d errors", errors);

        $finish;
    end
endmodule
