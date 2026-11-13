`timescale 1ns/1ps

module tb_InstructionAdder;
    reg [31:0] instr_addr;
    wire [31:0] instr_addr_plus4;

    reg [31:0] expected;
    integer i;
    integer errors;
    integer random_tests;

    InstructionAdder dut (
        .instr_addr(instr_addr),
        .instr_addr_plus4(instr_addr_plus4)
    );

    initial begin

        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/InstructionAdder/InstructionAdder.vcd");
            $dumpvars(0, tb_InstructionAdder);
        end
        errors = 0;
        if (!$value$plusargs("random_tests=%d", random_tests))
            random_tests = 100000;
        if (random_tests < 0)
            $fatal(1, "random_tests must be nonnegative");

        for(i=2; i<=32; i=i+1) begin
            instr_addr = (32'h1 << i) - 32'd4;
            #1;
            expected = instr_addr + 32'd4;

            if (instr_addr_plus4 !== expected) begin
                errors = errors + 1;
                $display("instr_addr:%h, instr_addr_plus4:%h, expected:%h",
                        instr_addr, instr_addr_plus4, expected);
            end
        end

        repeat(random_tests) begin
            instr_addr = $urandom;

            #1;

            expected = instr_addr + 32'd4;

            if (instr_addr_plus4 !== expected) begin
                errors = errors + 1;
                $display("instr_addr:%h, instr_addr_plus4:%h, expected:%h",
                instr_addr, instr_addr_plus4, expected);
            end
        end

        if (errors == 0)
            $display("PASS");
        else
            $fatal(1, "FAIL: %0d errors", errors);

        $finish;

    end

endmodule
