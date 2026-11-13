`timescale 1ns/1ps

module tb_ImmediateGenerator;
    reg [31:0] instruction;
    reg [2:0] control;
    wire [31:0] immediate;

    reg [31:0] value;

    integer i;
    integer errors;
    integer random_tests;
    integer tests;

    ImmediateGenerator dut (
        .instruction(instruction),
        .control(control),
        .immediate(immediate)
    );

    task check;
        input [2:0] format;
        input [31:0] expected;

        begin
            // Random values in bits that do not belong to immediate
            instruction = $urandom;
            control = format;

            // Encode the expected value into the instruction
            case (format)
                3'b000: begin
                    instruction[31:20] = expected[11:0];
                end

                3'b001: begin
                    instruction[31:25] = expected[11:5];
                    instruction[11:7] = expected[4:0];
                end

                3'b010: begin
                    instruction[31] = expected[12];
                    instruction[7] = expected[11];
                    instruction[30:25] = expected[10:5];
                    instruction[11:8] = expected[4:1];
                end

                3'b011: begin
                    instruction[31:12] = expected[31:12];
                end

                3'b100: begin
                    instruction[31] = expected[20];
                    instruction[19:12] = expected[19:12];
                    instruction[20] = expected[11];
                    instruction[30:21] = expected[10:1];
                end

                default: begin
                    // Instruction remains random
                end
            endcase

            #1;

            tests = tests + 1;

            if (immediate !== expected) begin
                errors = errors + 1;
                $display(
                    "FAIL: control=%b instruction=%h immediate=%h expected=%h",
                    control, instruction, immediate, expected);
            end
        end
    endtask

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/ImmediateGenerator/ImmediateGenerator.vcd");
            $dumpvars(0, tb_ImmediateGenerator);
        end

        errors = 0;
        if (!$value$plusargs("random_tests=%d", random_tests))
            random_tests = 10000;
        if (random_tests < 0)
            $fatal(1, "random_tests must be nonnegative");
        tests = 0;

        // I: -2048 to 2047
        check(3'b000, 32'd0);
        check(3'b000, 32'd1);
        check(3'b000, -32'd1);
        check(3'b000, 32'd2047);
        check(3'b000, -32'd2048);

        // S: -2048 to 2047
        check(3'b001, 32'd0);
        check(3'b001, 32'd1);
        check(3'b001, -32'd1);
        check(3'b001, 32'd2047);
        check(3'b001, -32'd2048);

        // B: -4096 to 4094, multiples of 2
        check(3'b010, 32'd0);
        check(3'b010, 32'd2);
        check(3'b010, -32'd2);
        check(3'b010, 32'd4094);
        check(3'b010, -32'd4096);

        // U: lower 12 bits are zero
        check(3'b011, 32'h00000000);
        check(3'b011, 32'h00001000);
        check(3'b011, 32'h7FFFF000);
        check(3'b011, 32'h80000000);
        check(3'b011, 32'hFFFFF000);

        // J: -1048576 to 1048574, multiples of 2
        check(3'b100, 32'd0);
        check(3'b100, 32'd2);
        check(3'b100, -32'd2);
        check(3'b100, 32'd1048574);
        check(3'b100, -32'd1048576);

        repeat(random_tests) begin
            // Signed 12-bit value
            value = $urandom;
            value = $signed(value) >>> 20;
            check(3'b000, value);
            check(3'b001, value);

            // Signed 13-bit value, bit 0 = 0
            value = $urandom;
            value = $signed(value) >>> 19;
            value = value & 32'hFFFFFFFE;
            check(3'b010, value);

            // Arbitrary upper 20 bits, lower 12 bits = 0
            value = $urandom;
            value = value & 32'hFFFFF000;
            check(3'b011, value);

            // Signed 21-bit value, bit 0 = 0
            value = $urandom;
            value = $signed(value) >>> 11;
            value = value & 32'hFFFFFFFE;
            check(3'b100, value);

            // Unused control codes must produce zero
            for(i=5; i<8; i=i+1) begin
                check(i[2:0], 32'b0);
            end
        end

        if (errors == 0)
            $display("PASS: ImmediateGenerator (%0d tests)", tests);
        else
            $fatal(1, "FAIL: %0d errors", errors);

        $finish;
    end
endmodule
