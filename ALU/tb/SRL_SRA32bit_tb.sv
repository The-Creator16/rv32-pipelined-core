`timescale 1ns/1ps

module tb_SRL_SRA32bit;

    reg [31:0] a;
    reg [4:0] shamt;
    reg variant;

    wire [31:0] res;

    reg [31:0] expected;
    reg [31:0] boundary_inputs [0:5];

    integer i, j, k;
    integer errors;
    integer random_tests;

    SRL_SRA32bit dut (
        .a(a),
        .shamt(shamt),
        .variant(variant),
        .res(res)
    );

    task check_boundary_inputs;
        boundary_inputs[0] = 32'h00000000;
        boundary_inputs[1] = 32'hFFFFFFFF;
        boundary_inputs[2] = 32'h00000001;
        boundary_inputs[3] = 32'h80000000;
        boundary_inputs[4] = 32'hAAAAAAAA;
        boundary_inputs[5] = 32'h55555555;

        for(i=0; i<6; i=i+1) begin
            for(j=0; j<32; j=j+1) begin
                for(k=0; k<2; k=k+1) begin
                    a = boundary_inputs[i];
                    shamt = j;
                    variant = k;

                    if (variant)
                        expected = $signed(a) >>> shamt;
                    else
                        expected = a >> shamt;

                    #1;

                    if (res !== expected) begin
                        errors = errors + 1;
                        $display(
                            "FAIL: a=%d shamt=%d variant=%b result=%b expected=%b",
                            a, shamt, variant, res, expected);
                    end
                end
            end
        end
    endtask

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/ALU/SRL_SRA32bit.vcd");
            $dumpvars(0, tb_SRL_SRA32bit);
        end

        errors = 0;
        if (!$value$plusargs("random_tests=%d", random_tests))
            random_tests = 200000;
        if (random_tests < 0)
            $fatal(1, "random_tests must be nonnegative");

        repeat(random_tests) begin
            a = $urandom;
            shamt = $urandom_range(31, 0);
            variant = $urandom_range(1, 0);

            if (variant)
                expected = $signed(a) >>> shamt;
            else
                expected = a >> shamt;

            #1;

            if (res !== expected) begin
                errors = errors + 1;
                $display(
                    "FAIL: a=%d shamt=%d variant=%b result=%b expected=%b",
                    a, shamt, variant, res, expected);
            end
        end

        check_boundary_inputs();

        if (errors == 0)
            $display("PASS: SRL_SRA32bit (%0d random input pairs plus boundary tests)", random_tests);
        else
            $fatal(1, "FAIL: %0d errors", errors);

        $finish;
    end
endmodule
