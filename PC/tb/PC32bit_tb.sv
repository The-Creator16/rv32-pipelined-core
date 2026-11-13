`timescale 1ns/1ps

module tb_PC32bit;

    reg [31:0] pc_in;
    reg enable;
    reg reset;
    reg clk;
    wire [31:0] pc_out;

    reg [31:0] expected;
    reg [31:0] pc_prev;

    integer i;
    integer errors;
    integer random_tests;

    PC32bit dut (
        .pc_in(pc_in),
        .enable(enable),
        .reset(reset),
        .clk(clk),
        .pc_out(pc_out)
    );

    task check_output(input [31:0] expected_output);
        if (pc_out !== expected_output) begin
            errors = errors + 1;
            $display(
                "FAIL: time=%0t pc_in=%h enable=%b reset=%b clk=%b pc_out=%h expected=%h",
                $time, pc_in, enable, reset, clk, pc_out, expected_output
            );
        end
    endtask

    task check_reset;
        for(i=0; i<2; i=i+1) begin
            @(negedge clk);
            reset = 1;
            enable = i;
            expected = 32'b0;

            @(posedge clk);
            #1;
            check_output(expected);
        end
    endtask

    task check_cycle(input [31:0] next_pc, input next_enable, input next_reset);
        @(negedge clk);
        pc_prev = expected;
        pc_in = next_pc;
        enable = next_enable;
        reset = next_reset;

        // the output must hold until the next positive clock edge.
        #1;
        check_output(pc_prev);

        if (reset)
            expected = 32'b0;
        else if (enable)
            expected = pc_in;

        @(posedge clk);
        #1;
        check_output(expected);
    endtask

    task check_directed_inputs;
        check_cycle(32'hFFFFFFFF, 1, 0);
        repeat(4)
            check_cycle($urandom, 0, 0);

        // reset must clear a nonzero value with either enable setting.
        check_cycle(32'h12345678, 1, 1);
        check_cycle(32'h80000000, 1, 0);
        check_cycle(32'hFFFFFFFF, 0, 1);

        check_cycle(32'hAAAAAAAA, 0, 0);
        check_cycle(32'h00000000, 1, 0);
        check_cycle(32'h55555555, 1, 0);
        check_cycle(32'hAAAAAAAA, 1, 0);
        check_cycle(32'h00000001, 1, 0);
    endtask

    task check_random_inputs;
        repeat(random_tests)
            check_cycle($urandom, $urandom_range(1, 0), $urandom_range(15, 0) == 0);
    endtask

    initial begin
        clk = 0;
        forever
            #2 clk = ~clk;
    end

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/PC/PC32bit.vcd");
            $dumpvars(0, tb_PC32bit);
        end

        pc_in = 32'b0;
        errors = 0;
        if (!$value$plusargs("random_tests=%d", random_tests))
            random_tests = 200000;
        if (random_tests < 0)
            $fatal(1, "random_tests must be nonnegative");

        check_reset();
        check_directed_inputs();
        check_random_inputs();

        if (errors == 0)
            $display("PASS: PC32bit (%0d random cycles plus reset and directed tests)", random_tests);
        else
            $fatal(1, "FAIL: %0d errors", errors);

        $finish;
    end

endmodule
