`timescale 1ns/1ps

module tb_OverflowDetector;

    reg a_sign;
    reg b_sign;
    reg res_sign;

    wire overflow_add;
    wire overflow_sub;

    reg expected_overflow_add;
    reg expected_overflow_sub;

    integer i, j, k;
    integer errors;

    OverflowDetector dut (
        .a_sign(a_sign),
        .b_sign(b_sign),
        .res_sign(res_sign),
        .overflow_add(overflow_add),
        .overflow_sub(overflow_sub)
    );

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/ALU/OverflowDetector.vcd");
            $dumpvars(0, tb_OverflowDetector);
        end

        errors = 0;

        for(i=0; i<2; i=i+1) begin
            for(j=0; j<2; j=j+1) begin
                for(k=0; k<2; k=k+1) begin
                    a_sign = i;
                    b_sign = j;
                    res_sign = k;

                    expected_overflow_add = (a_sign == b_sign)
                        && (res_sign != a_sign);

                    expected_overflow_sub = (a_sign != b_sign)
                        && (res_sign != a_sign);

                    #1;

                    if ((overflow_add !== expected_overflow_add) || (overflow_sub !== expected_overflow_sub)) begin
                        errors = errors + 1;
                        $display(
                            "FAIL: a=%b b=%b res=%b overflow_add=%b overflow_sub=%b expected_overflow_add=%b expected_overflow_sub=%b",
                            a_sign, b_sign, res_sign, overflow_add, overflow_sub, expected_overflow_add, expected_overflow_sub);
                    end
                end
            end
        end

        if (errors == 0)
            $display("PASS: all 8 tests");
        else
            $fatal(1, "FAIL: %0d errors", errors);

        $finish;
    end
endmodule
