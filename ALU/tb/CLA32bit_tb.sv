`timescale 1ns/1ps

module tb_CLA32bit;

    reg [31:0] a;
    reg [31:0] b;
    reg carry_in;

    wire [31:0] res;
    wire carry_out;

    reg [32:0] expected;

    integer i;
    integer errors;
    integer random_tests;

    CLA32bit dut (
        .a(a),
        .b(b),
        .carry_in(carry_in),
        .res(res),
        .carry_out(carry_out)
    );

    task check_boundary_inputs;
        for(i=0; i<2; i=i+1) begin
            a = 32'b0;
            b = 32'b0;
            carry_in = i;

            expected = {1'b0, a}
                     + {1'b0, b}
                     + {32'b0, carry_in};

            #1;

            if ({carry_out, res} !== expected) begin
                errors = errors + 1;
                $display(
                    "FAIL: a=%d b=%d cin=%b result=%b expected=%b",
                    a, b, carry_in,
                    {carry_out, res}, expected);
            end
        end

        for(i=0; i<2; i=i+1) begin
            a = 32'hFFFFFFFF;
            b = 32'hFFFFFFFF;
            carry_in = i;

            expected = {1'b0, a}
                     + {1'b0, b}
                     + {32'b0, carry_in};

            #1;

            if ({carry_out, res} !== expected) begin
                errors = errors + 1;
                $display(
                    "FAIL: a=%d b=%d cin=%b result=%b expected=%b",
                    a, b, carry_in,
                    {carry_out, res}, expected);
            end
        end

        for(i=0; i<2; i=i+1) begin
            a = 32'hFFFFFFFF;
            b = 32'b1 - i;
            carry_in = i;

            expected = {1'b0, a}
                     + {1'b0, b}
                     + {32'b0, carry_in};

            #1;

            if ({carry_out, res} !== expected) begin
                errors = errors + 1;
                $display(
                    "FAIL: a=%d b=%d cin=%b result=%b expected=%b",
                    a, b, carry_in,
                    {carry_out, res}, expected);
            end
        end
    endtask

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/ALU/CLA32bit.vcd");
            $dumpvars(0, tb_CLA32bit);
        end

        errors = 0;
        if (!$value$plusargs("random_tests=%d", random_tests))
            random_tests = 200000;
        if (random_tests < 0)
            $fatal(1, "random_tests must be nonnegative");

        repeat(random_tests) begin
            a = $urandom;
            b = $urandom;
            carry_in = $urandom_range(1, 0);

            expected = {1'b0, a}
                     + {1'b0, b}
                     + {32'b0, carry_in};

            #1;

            if ({carry_out, res} !== expected) begin
                errors = errors + 1;
                $display(
                    "FAIL: a=%d b=%d cin=%b result=%b expected=%b",
                    a, b, carry_in,
                    {carry_out, res}, expected);
            end
        end

        check_boundary_inputs();

        if (errors == 0)
            $display("PASS: CLA32bit (%0d random input pairs plus boundary tests)", random_tests);
        else
            $fatal(1, "FAIL: %0d errors", errors);

        $finish;
    end

endmodule
