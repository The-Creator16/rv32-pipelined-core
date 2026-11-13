`timescale 1ns/1ps

module tb_InstructionMemory;
    reg [31:0] inst_address;
    wire [31:0] instruction;

    integer errors;

    InstructionMemory dut (
        .inst_address(inst_address),
        .instruction(instruction)
    );

    task instruction_check;
        input [31:0] address;
        input [31:0] expected;

        begin
            inst_address = address;

            #1;

            if (instruction !== expected) begin
                errors = errors + 1;
                $display(
                    "FAIL: address=%h instruction=%h expected=%h",
                    inst_address, instruction, expected
                );
            end
        end
    endtask

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/InstructionMemory/InstructionMemory.vcd");
            $dumpvars(0, tb_InstructionMemory);
        end

        errors = 0;

        // Sequential reads
        instruction_check(32'd0, 32'h00500093);
        instruction_check(32'd4, 32'h00308113);
        instruction_check(32'd8, 32'h002081B3);
        instruction_check(32'd12, 32'h00302023);

        // Last word in the 4 KiB memory
        instruction_check(32'd4092, 32'h00000013);

        // Reads in a different order
        instruction_check(32'd8, 32'h002081B3);
        instruction_check(32'd0, 32'h00500093);
        instruction_check(32'd12, 32'h00302023);
        instruction_check(32'd4, 32'h00308113);

        if (errors == 0)
            $display("PASS");
        else
            $fatal(1, "FAIL: %0d errors", errors);

        $finish;
    end
endmodule
