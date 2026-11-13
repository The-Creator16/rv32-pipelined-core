`timescale 1ns/1ps

module tb_CLA4bit;

    reg [3:0] a;
    reg [3:0] b;
    reg carry_in;

    wire [3:0] p;
    wire [2:0] g;
    wire [3:0] res;

    reg [4:0] expected;

    integer i, j, k;
    integer errors;

    assign p = a ^ b;
    assign g = a[2:0] & b[2:0];

    CLA4bit dut (
        .p(p),
        .g(g),
        .carry_in(carry_in),
        .res(res)
    );

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/ALU/CLA4bit.vcd");
            $dumpvars(0, tb_CLA4bit);
        end

        errors = 0;

        for(i=0; i<16; i=i+1) begin
            for(j=0; j<16; j=j+1) begin
                for(k=0; k<2; k=k+1) begin
                    a = i;
                    b = j;
                    carry_in = k;

                    expected = {1'b0, a}
                             + {1'b0, b}
                             + {4'b0000, carry_in};

                    #1;

                    if (res !== expected[3:0]) begin
                        errors = errors + 1;
                        $display(
                            "FAIL: a=%d b=%d p=%b g=%b cin=%b result=%b expected=%b",
                            a, b, p, g, carry_in,
                            res, expected[3:0]
                        );
                    end
                end
            end
        end

        if (errors == 0)
            $display("PASS: all 512 input combinations of a, b and carry_in");
        else
            $fatal(1, "FAIL: %0d errors", errors);

        $finish;
    end

endmodule
