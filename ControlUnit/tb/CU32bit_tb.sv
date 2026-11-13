`timescale 1ns/1ps

module tb_CU32bit;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;

    wire [2:0] immd_type;
    wire [2:0] alu_control;
    wire alu_variant;
    wire alu_src;
    wire is_lui;
    wire is_auipc;
    wire is_branch;
    wire [1:0] branch_type;
    wire is_jump;
    wire is_jalr;
    wire mem_write;
    wire reg_write;
    wire mem_to_reg;
    wire [1:0] mem_size;
    wire load_unsigned;

    wire [20:0] actual;
    assign actual = {immd_type, alu_control, alu_variant, alu_src, is_lui, is_auipc, is_branch, branch_type, is_jump, is_jalr, mem_write, reg_write, mem_to_reg, mem_size, load_unsigned};

    localparam integer RULES = 37;
    reg [16:0] rule_mask [0:RULES-1];
    reg [16:0] rule_code [0:RULES-1];
    reg [20:0] rule_output [0:RULES-1];
    integer hits [0:RULES-1];
    integer rule_count;
    integer errors;
    integer tests;
    integer supported;
    integer unsupported;
    integer i, j, pass;

    CU32bit dut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .immd_type(immd_type),
        .alu_control(alu_control),
        .alu_variant(alu_variant),
        .alu_src(alu_src),
        .is_lui(is_lui),
        .is_auipc(is_auipc),
        .is_branch(is_branch),
        .branch_type(branch_type),
        .is_jump(is_jump),
        .is_jalr(is_jalr),
        .mem_write(mem_write),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .mem_size(mem_size),
        .load_unsigned(load_unsigned)
    );

    task add_rule;
        input [16:0] mask;
        input [16:0] code;
        input [20:0] controls;
        begin
            if (rule_count >= RULES)
                $fatal(1, "Too many golden rules");
            rule_mask[rule_count] = mask;
            rule_code[rule_count] = code;
            rule_output[rule_count] = controls;
            hits[rule_count] = 0;
            rule_count = rule_count + 1;
        end
    endtask

    task check;
        input [16:0] key;
        integer k;
        integer found;
        integer match_count;
        begin
            {opcode, funct3, funct7} = key;
            #1;
            found = -1;
            match_count = 0;
            for(k=0; k<RULES; k=k+1) begin
                if ((key & rule_mask[k]) == rule_code[k]) begin
                    found = k;
                    match_count = match_count + 1;
                end
            end
            if (match_count > 1)
                $fatal(1, "Overlapping golden rules: key=%h", key);

            tests = tests + 1;
            if ((^actual) === 1'bx) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("UNKNOWN: opcode=%b funct3=%b funct7=%b controls=%h",
                             opcode, funct3, funct7, actual);
            end

            if (found >= 0) begin
                supported = supported + 1;
                hits[found] = hits[found] + 1;
                if (actual !== rule_output[found]) begin
                    errors = errors + 1;
                    if (errors <= 20)
                        $display("DECODE FAIL: opcode=%b funct3=%b funct7=%b got=%h expected=%h rule=%0d",
                                 opcode, funct3, funct7, actual, rule_output[found], found);
                end
            end else begin
                unsupported = unsupported + 1;
                // Do not prescribe irrelevant ALU/immediate controls.
                // Unsupported encodings must not cause any side effects.
                if ({reg_write, mem_write, is_branch, is_jump, is_jalr}
                    !== 5'b00000) begin
                    errors = errors + 1;
                    if (errors <= 20)
                        $display("UNSUPPORTED FAIL: opcode=%b funct3=%b funct7=%b controls=%h",
                                 opcode, funct3, funct7, actual);
                end
            end
        end
    endtask

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/ControlUnit/CU32bit.vcd");
            $dumpvars(0, tb_CU32bit);
        end

        opcode = 7'b0;
        funct3 = 3'b0;
        funct7 = 7'b0;
        errors = 0;
        tests = 0;
        supported = 0;
        unsupported = 0;
        rule_count = 0;

        // ADD
        add_rule(17'h1FFFF, 17'h0CC00, {3'b000, 3'b000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // SUB
        add_rule(17'h1FFFF, 17'h0CC20, {3'b000, 3'b000, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // SLL
        add_rule(17'h1FFFF, 17'h0CC80, {3'b000, 3'b101, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // SLT
        add_rule(17'h1FFFF, 17'h0CD00, {3'b000, 3'b110, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // SLTU
        add_rule(17'h1FFFF, 17'h0CD80, {3'b000, 3'b111, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // XOR
        add_rule(17'h1FFFF, 17'h0CE00, {3'b000, 3'b100, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // SRL
        add_rule(17'h1FFFF, 17'h0CE80, {3'b000, 3'b001, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // SRA
        add_rule(17'h1FFFF, 17'h0CEA0, {3'b000, 3'b001, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // OR
        add_rule(17'h1FFFF, 17'h0CF00, {3'b000, 3'b011, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // AND
        add_rule(17'h1FFFF, 17'h0CF80, {3'b000, 3'b010, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // ADDI
        add_rule(17'h1FF80, 17'h04C00, {3'b000, 3'b000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // SLTI
        add_rule(17'h1FF80, 17'h04D00, {3'b000, 3'b110, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // SLTIU
        add_rule(17'h1FF80, 17'h04D80, {3'b000, 3'b111, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // XORI
        add_rule(17'h1FF80, 17'h04E00, {3'b000, 3'b100, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // ORI
        add_rule(17'h1FF80, 17'h04F00, {3'b000, 3'b011, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // ANDI
        add_rule(17'h1FF80, 17'h04F80, {3'b000, 3'b010, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // SLLI
        add_rule(17'h1FFFF, 17'h04C80, {3'b000, 3'b101, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // SRLI
        add_rule(17'h1FFFF, 17'h04E80, {3'b000, 3'b001, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // SRAI
        add_rule(17'h1FFFF, 17'h04EA0, {3'b000, 3'b001, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // LB
        add_rule(17'h1FF80, 17'h00C00, {3'b000, 3'b000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b00, 1'b0});
        // LH
        add_rule(17'h1FF80, 17'h00C80, {3'b000, 3'b000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b01, 1'b0});
        // LW
        add_rule(17'h1FF80, 17'h00D00, {3'b000, 3'b000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b10, 1'b0});
        // LBU
        add_rule(17'h1FF80, 17'h00E00, {3'b000, 3'b000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b00, 1'b1});
        // LHU
        add_rule(17'h1FF80, 17'h00E80, {3'b000, 3'b000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 2'b01, 1'b1});
        // SB
        add_rule(17'h1FF80, 17'h08C00, {3'b001, 3'b000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, 1'b0});
        // SH
        add_rule(17'h1FF80, 17'h08C80, {3'b001, 3'b000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b01, 1'b0});
        // SW
        add_rule(17'h1FF80, 17'h08D00, {3'b001, 3'b000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b10, 1'b0});
        // BEQ
        add_rule(17'h1FF80, 17'h18C00, {3'b010, 3'b000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b10, 1'b0});
        // BNE
        add_rule(17'h1FF80, 17'h18C80, {3'b010, 3'b000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b01, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b10, 1'b0});
        // BLT
        add_rule(17'h1FF80, 17'h18E00, {3'b010, 3'b110, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 2'b11, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b10, 1'b0});
        // BGE
        add_rule(17'h1FF80, 17'h18E80, {3'b010, 3'b110, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b10, 1'b0});
        // BLTU
        add_rule(17'h1FF80, 17'h18F00, {3'b010, 3'b111, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 2'b11, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b10, 1'b0});
        // BGEU
        add_rule(17'h1FF80, 17'h18F80, {3'b010, 3'b111, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b10, 1'b0});
        // JAL
        add_rule(17'h1FC00, 17'h1BC00, {3'b100, 3'b000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // JALR
        add_rule(17'h1FF80, 17'h19C00, {3'b000, 3'b000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 2'b00, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // LUI
        add_rule(17'h1FC00, 17'h0DC00, {3'b011, 3'b000, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});
        // AUIPC
        add_rule(17'h1FC00, 17'h05C00, {3'b011, 3'b000, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 2'b00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'b10, 1'b0});

        if (rule_count != RULES)
            $fatal(1, "Missing golden rules");

        for(pass=0; pass<2; pass=pass+1) begin
            for(i=0; i<131072; i=i+1) begin
                if (pass == 0)
                    check(i[16:0]);
                else
                    check(17'h1FFFF - i[16:0]);
            end
        end

        for(j=0; j<RULES; j=j+1) begin
            if (hits[j] == 0)
                $fatal(1, "Untested golden rule: %0d", j);
        end

        $display("Tests=%0d supported=%0d unsupported=%0d errors=%0d",
                 tests, supported, unsupported, errors);
        if (errors == 0)
            $display("PASS: all 131072 input combinations, two passes, 37 instruction rules");
        else
            $fatal(1, "FAIL: %0d errors", errors);
        $finish;
    end
endmodule
