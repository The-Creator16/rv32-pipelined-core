`timescale 1ns/1ps

module tb_EarlyBranchingAdder;

    reg [31:0] a;
    reg [31:0] b;

    wire [31:0] res;

    reg [31:0] expected;

    integer i;
    integer errors;
    integer random_tests;

    EarlyBranchingAdder dut (
        .a(a),
        .b(b),
        .res(res)
    );

    task check_boundary_inputs;
        a = 32'b0;
        b = 32'b0;

        expected = a + b;

        #1;

        if (res !== expected) begin
            errors = errors + 1;
            $display(
                "FAIL: a=%d b=%d result=%b expected=%b",
                a, b, res, expected);
        end

        a = 32'hFFFFFFFF;
        b = 32'hFFFFFFFF;

        expected = a + b;

        #1;

        if (res !== expected) begin
            errors = errors + 1;
            $display(
                "FAIL: a=%d b=%d result=%b expected=%b",
                a, b, res, expected);
        end

        for(i=0; i<2; i=i+1) begin
            a = 32'hFFFFFFFF;
            b = 32'b1 - i;

            expected = a + b;

            #1;

            if (res !== expected) begin
                errors = errors + 1;
                $display(
                    "FAIL: a=%d b=%d result=%b expected=%b",
                    a, b, res, expected);
            end
        end

        for(i=1; i<32; i=i+1) begin
            a = (32'h1 << i) - 32'd1;
            b = 32'd1;

            expected = a + b;

            #1;

            if (res !== expected) begin
                errors = errors + 1;
                $display(
                    "FAIL: a=%h b=%h result=%h expected=%h",
                    a, b, res, expected);
            end
        end
    endtask

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/EarlyBranchingAdder/EarlyBranchingAdder.vcd");
            $dumpvars(0, tb_EarlyBranchingAdder);
        end

        errors = 0;
        if (!$value$plusargs("random_tests=%d", random_tests))
            random_tests = 200000;
        if (random_tests < 0)
            $fatal(1, "random_tests must be nonnegative");

        repeat(random_tests) begin
            a = $urandom;
            b = $urandom;

            expected = a + b;

            #1;

            if (res !== expected) begin
                errors = errors + 1;
                $display(
                    "FAIL: a=%d b=%d result=%b expected=%b",
                    a, b, res, expected);
            end
        end

        check_boundary_inputs();

        if (errors == 0)
            $display("PASS: EarlyBranchingAdder (%0d random input pairs plus boundary tests)", random_tests);
        else
            $fatal(1, "FAIL: %0d errors", errors);

        $finish;
    end

endmodule
