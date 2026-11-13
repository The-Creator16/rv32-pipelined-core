`timescale 1ns/1ps

module tb_ALU32bit;

    reg [31:0] a;
    reg [31:0] b;
    reg variant;
    reg [2:0] alu_control;
    wire [31:0] alu_res;
    wire equal;
    wire overflow;

    reg [31:0] boundary_inputs [0:10];

    reg [31:0] expected;

    integer i, j;
    integer errors;
    integer random_tests;

    ALU32bit dut (
        .a(a),
        .b(b),
        .variant(variant),
        .alu_control(alu_control),
        .alu_res(alu_res),
        .equal(equal),
        .overflow(overflow)
    );

    task check_result(input [31:0] expected_result, input expected_overflow);
        #1;
        if (alu_res !== expected_result || equal !== (a == b) || overflow !== expected_overflow) begin
            errors = errors + 1;
            $display("FAIL: a=%h b=%h alu_control=%b variant=%b", a, b, alu_control, variant);
            $display("alu_res=%h expected=%h equal=%b expected=%b overflow=%b expected=%b",
                     alu_res, expected_result, equal, (a == b), overflow, expected_overflow);
        end
    endtask

    task check_operations;
        //------------ADDITION------------
        alu_control = 3'b000;
        variant = 0;
        expected = a + b;
        check_result(expected, (a[31] == b[31]) && (expected[31] != a[31]));

        //------------SUBTRACTION------------
        variant = 1;
        expected = a - b;
        check_result(expected, (a[31] != b[31]) && (expected[31] != a[31]));

        //------------SRL / SRA------------
        alu_control = 3'b001;
        variant = 0;
        check_result(a >> b[4:0], 0);
        variant = 1;
        check_result($signed(a) >>> b[4:0], 0);

        variant = 0;
        alu_control = 3'b010;
        check_result(a & b, 0);
        alu_control = 3'b011;
        check_result(a | b, 0);
        alu_control = 3'b100;
        check_result(a ^ b, 0);
        alu_control = 3'b101;
        check_result(a << b[4:0], 0);

        //------------SLT / SLTU------------
        variant = 1;
        alu_control = 3'b110;
        check_result({31'b0, ($signed(a) < $signed(b))}, 0);
        alu_control = 3'b111;
        check_result({31'b0, (a < b)}, 0);
    endtask

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/ALU/ALU32bit.vcd");
            $dumpvars(0, tb_ALU32bit);
        end

        boundary_inputs[0] = 32'h00000000;
        boundary_inputs[1] = 32'h00000001;
        boundary_inputs[2] = 32'h00000002;
        boundary_inputs[3] = 32'h7FFFFFFE;
        boundary_inputs[4] = 32'h7FFFFFFF;
        boundary_inputs[5] = 32'h80000000;
        boundary_inputs[6] = 32'h80000001;
        boundary_inputs[7] = 32'hFFFFFFFE;
        boundary_inputs[8] = 32'hFFFFFFFF;
        boundary_inputs[9] = 32'hAAAAAAAA;
        boundary_inputs[10] = 32'h55555555;

        errors = 0;
        if (!$value$plusargs("random_tests=%d", random_tests))
            random_tests = 200000;
        if (random_tests < 0)
            $fatal(1, "random_tests must be nonnegative");

        for(i=0; i<11; i=i+1)
            for(j=0; j<11; j=j+1) begin
                a = boundary_inputs[i];
                b = boundary_inputs[j];
                check_operations();
            end

        repeat(random_tests) begin
            a = $urandom;
            b = $urandom;
            check_operations();
        end

        if (errors == 0)
            $display("PASS: ALU32bit (%0d random input pairs plus boundary tests)", random_tests);
        else
            $fatal(1, "FAIL: %0d errors", errors);

        $finish;
    end
endmodule
