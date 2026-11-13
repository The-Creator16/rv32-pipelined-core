`timescale 1ns/1ps

module tb_CPU32bit;
    reg clk;
    reg reset;

    CPU32bit #(.PROGRAM_FILE("CPU/tb/pipeline.hex")) dut (
        .clk(clk),
        .reset(reset)
    );

    initial begin
        clk = 0;
        forever #2 clk = ~clk;
    end

    task check_register(input [4:0] addr, input [31:0] expected);
        if (dut.RF.q[addr] !== expected)
            $fatal(1, "x%0d=%h expected=%h", addr, dut.RF.q[addr], expected);
    endtask

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/CPU/CPU32bit.vcd");
            $dumpvars(0, tb_CPU32bit);
        end
        reset = 1;
        repeat(2) @(negedge clk);
        #1;
        reset = 0;
        repeat(48) @(posedge clk);
        #1;
        check_register(0, 0);
        check_register(1, 5);
        check_register(2, 8);
        check_register(3, 13);
        check_register(4, 13);
        check_register(5, 14);
        check_register(6, 15);
        check_register(7, 44);
        check_register(8, 45);
        if (dut.DM.memory[0] !== 32'd13)
            $fatal(1, "Unexpected store at address zero");
        $display("PASS: CPU32bit pipeline program");
        $finish;
    end
endmodule
