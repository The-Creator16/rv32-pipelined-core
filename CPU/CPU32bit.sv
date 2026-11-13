`timescale 1ns/1ps

module CPU32bit #(
    parameter PROGRAM_FILE = "InstructionMemory/program.hex",
    parameter DATA_FILE = "DataMemory/data.hex"
) (
    input wire clk,
    input wire reset
);

    // IF data
    wire [31:0] instr_addr_in_f;
    wire [31:0] pc_plus4_f;
    wire [31:0] instr_addr_out_f;
    wire [31:0] instr_f;

    // ID data
    reg [31:0] instr_d;
    reg [31:0] pc_plus4_d;
    reg [31:0] pc_d;
    wire [31:0] reg0_d;
    wire [31:0] reg1_d;
    wire [31:0] immediate_d;
    wire [31:0] predicted_target_d;

    // ID control
    wire [2:0] immd_type_d;
    wire [2:0] alu_control_d;
    wire alu_variant_d;
    wire alu_src_d;
    wire is_lui_d;
    wire is_auipc_d;
    wire is_branch_d;
    wire [1:0] branch_type_d;
    wire is_jump_d;
    wire is_jalr_d;
    wire mem_write_d;
    wire reg_write_d;
    wire mem_to_reg_d;
    wire [1:0] mem_size_d;
    wire load_unsigned_d;

    // EX data
    reg [31:0] src_a_e;
    reg [4:0] rs1_e;
    reg [31:0] src_reg_b_e;
    reg [4:0] rs2_e;
    reg [4:0] reg_addr_e;
    reg [31:0] immediate_e;
    reg [31:0] pc_plus4_e;
    reg [31:0] pc_e;
    wire [31:0] pc_branch_e;
    wire [31:0] src_b_e;
    wire [31:0] alu_out_e;
    wire alu_equal_e;
    wire alu_overflow_e;
    wire [31:0] branch_src_e;
    wire [31:0] jump_address_e;
    wire branch_taken_e;
    wire [31:0] src_choose_a_e;

    // EX forwarding
    wire forward_a_m;
    wire forward_b_m;
    wire forward_a_w;
    wire forward_b_w;
    wire [31:0] forwarded_a_e;
    wire [31:0] forwarded_b_e;

    // Branch prediction and redirect
    wire predict_taken_d;
    wire branch_mispredict_e;
    wire redirect_e;
    wire [31:0] redirect_address_e;

    // EX control
    reg [2:0] alu_control_e;
    reg alu_variant_e;
    reg alu_src_e;
    reg is_lui_e;
    reg is_auipc_e;
    reg is_branch_e;
    reg [1:0] branch_type_e;
    reg is_jump_e;
    reg is_jalr_e;
    reg mem_write_e;
    reg reg_write_e;
    reg mem_to_reg_e;
    reg [1:0] mem_size_e;
    reg load_unsigned_e;

    // MEM data
    reg [31:0] alu_out_m;
    reg [31:0] write_data_m;
    reg [4:0] reg_addr_m;
    reg [31:0] pc_plus4_m;
    wire [31:0] read_data_m;
    wire [31:0] forward_result_m;

    // MEM control
    reg mem_write_m;
    reg reg_write_m;
    reg mem_to_reg_m;
    reg is_jump_m;
    reg [1:0] mem_size_m;
    reg load_unsigned_m;

    // WB data
    reg [4:0] reg_addr_w;
    reg [31:0] alu_out_w;
    reg [31:0] read_data_w;
    reg [31:0] pc_plus4_w;
    wire [31:0] result_w;

    // WB control
    reg reg_write_w;
    reg mem_to_reg_w;
    reg is_jump_w;

    // IF control
    wire stall_f;
    wire pc_enable;

    // IF/ID control
    wire stall_d;
    wire flush_d;

    // ID/EX control
    wire flush_e;

    // Load-use hazard detection
    wire uses_rs1_d;
    wire uses_rs2_d;
    wire load_use_hazard;

    assign pc_enable = ~stall_f;

    assign uses_rs1_d = mem_write_d || is_branch_d ||
        (reg_write_d && !is_lui_d && !is_auipc_d &&
         (!is_jump_d || is_jalr_d));

    assign uses_rs2_d = mem_write_d || is_branch_d ||
        (reg_write_d && (instr_d[6:0] == 7'b0110011));

    assign load_use_hazard = reg_write_e && mem_to_reg_e &&
        (reg_addr_e != 5'b0) &&
        ((uses_rs1_d && (instr_d[19:15] == reg_addr_e)) ||
         (uses_rs2_d && (instr_d[24:20] == reg_addr_e)));

    assign predicted_target_d = pc_d + immediate_d;
    assign predict_taken_d = is_branch_d && !load_use_hazard && !redirect_e;

    assign branch_mispredict_e = is_branch_e && !branch_taken_e;
    assign redirect_e = is_jump_e || branch_mispredict_e;
    assign redirect_address_e = is_jump_e ? pc_branch_e : pc_plus4_e;

    assign stall_f = load_use_hazard && !redirect_e;
    assign stall_d = load_use_hazard && !redirect_e;

    assign flush_d = redirect_e || predict_taken_d;
    assign flush_e = redirect_e || load_use_hazard;

    // Fetch
    assign instr_addr_in_f = redirect_e ? redirect_address_e :
                          (predict_taken_d ? predicted_target_d : pc_plus4_f);

    PC32bit PC (
        .pc_in(instr_addr_in_f),
        .enable(pc_enable),
        .reset(reset),
        .clk(clk),
        .pc_out(instr_addr_out_f)
    );

    InstructionMemory #(.PROGRAM_FILE(PROGRAM_FILE)) IM (
        .inst_address(instr_addr_out_f),
        .instruction(instr_f)
    );

    InstructionAdder IA (
        .instr_addr(instr_addr_out_f),
        .instr_addr_plus4(pc_plus4_f)
    );

    always @(posedge clk) begin
        if (reset || flush_d) begin
            instr_d   <= 32'h00000013;
            pc_d      <= 32'b0;
            pc_plus4_d <= 32'b0;
        end else if (!stall_d) begin
            instr_d   <= instr_f;
            pc_d      <= instr_addr_out_f;
            pc_plus4_d <= pc_plus4_f;
        end
    end

    // Decode
    RegFile32bit RF (
        .read_addr_0(instr_d[19:15]),
        .read_addr_1(instr_d[24:20]),
        .write_addr(reg_addr_w),
        .write_data(result_w),
        .clk(clk),
        .write_enable(reg_write_w && !reset),
        .read_data_0(reg0_d),
        .read_data_1(reg1_d)
    );

    ImmediateGenerator IG (
        .instruction(instr_d),
        .control(immd_type_d),
        .immediate(immediate_d)
    );

    CU32bit CU (
        .opcode(instr_d[6:0]),
        .funct3(instr_d[14:12]),
        .funct7(instr_d[31:25]),

        .immd_type(immd_type_d),
        .alu_control(alu_control_d),
        .alu_variant(alu_variant_d),
        .alu_src(alu_src_d),
        .is_lui(is_lui_d),
        .is_auipc(is_auipc_d),

        .is_branch(is_branch_d),
        .branch_type(branch_type_d),
        .is_jump(is_jump_d),
        .is_jalr(is_jalr_d),

        .mem_write(mem_write_d),
        .reg_write(reg_write_d),
        .mem_to_reg(mem_to_reg_d),
        .mem_size(mem_size_d),
        .load_unsigned(load_unsigned_d)
    );

    always @(posedge clk) begin
        if (reset || flush_e) begin

            src_a_e       <= 32'b0;
            rs1_e        <= 5'b0;
            src_reg_b_e    <= 32'b0;
            rs2_e        <= 5'b0;
            reg_addr_e    <= 5'b0;
            immediate_e  <= 32'b0;
            pc_plus4_e    <= 32'b0;
            pc_e         <= 32'b0;

            alu_control_e <= 3'b0;
            alu_variant_e <= 1'b0;
            alu_src_e     <= 1'b0;
            is_lui_e      <= 1'b0;
            is_auipc_e    <= 1'b0;
            is_branch_e   <= 1'b0;
            branch_type_e <= 2'b0;
            is_jump_e     <= 1'b0;
            is_jalr_e     <= 1'b0;
            mem_write_e   <= 1'b0;
            reg_write_e   <= 1'b0;
            mem_to_reg_e   <= 1'b0;
            mem_size_e    <= 2'b10;
            load_unsigned_e <= 1'b0;
        end else begin

            src_a_e       <= reg0_d;
            rs1_e        <= instr_d[19:15];
            src_reg_b_e    <= reg1_d;
            rs2_e        <= instr_d[24:20];
            reg_addr_e    <= instr_d[11:7];
            immediate_e  <= immediate_d;
            pc_plus4_e    <= pc_plus4_d;
            pc_e         <= pc_d;

            alu_control_e <= alu_control_d;
            alu_variant_e <= alu_variant_d;
            alu_src_e     <= alu_src_d;
            is_lui_e      <= is_lui_d;
            is_auipc_e    <= is_auipc_d;
            is_branch_e   <= is_branch_d;
            branch_type_e <= branch_type_d;
            is_jump_e     <= is_jump_d;
            is_jalr_e     <= is_jalr_d;
            mem_write_e   <= mem_write_d;
            reg_write_e   <= reg_write_d;
            mem_to_reg_e   <= mem_to_reg_d;
            mem_size_e    <= mem_size_d;
            load_unsigned_e <= load_unsigned_d;
        end
    end

    // Execute
    assign src_b_e = alu_src_e ? immediate_e : forwarded_b_e;
    assign branch_src_e = is_jalr_e ? forwarded_a_e : pc_e;
    assign src_choose_a_e = is_lui_e ? 32'b0 : (is_auipc_e ? pc_e : forwarded_a_e);

    assign forward_a_m = reg_write_m && !mem_to_reg_m &&
        (reg_addr_m != 5'b0) && (reg_addr_m == rs1_e);
    assign forward_b_m = reg_write_m && !mem_to_reg_m &&
        (reg_addr_m != 5'b0) && (reg_addr_m == rs2_e);
    assign forward_a_w = reg_write_w &&
        (reg_addr_w != 5'b0) && (reg_addr_w == rs1_e);
    assign forward_b_w = reg_write_w &&
        (reg_addr_w != 5'b0) && (reg_addr_w == rs2_e);

    assign forward_result_m = is_jump_m ? pc_plus4_m : alu_out_m;
    assign forwarded_a_e = forward_a_m ? forward_result_m :
                        (forward_a_w ? result_w : src_a_e);
    assign forwarded_b_e = forward_b_m ? forward_result_m :
                        (forward_b_w ? result_w : src_reg_b_e);

    ALU32bit ALU (
        .a(src_choose_a_e),
        .b(src_b_e),
        .variant(alu_variant_e),
        .alu_control(alu_control_e),
        .alu_res(alu_out_e),
        .equal(alu_equal_e),
        .overflow(alu_overflow_e)
    );

    EarlyBranchingAdder EBA (
        .a(immediate_e),
        .b(branch_src_e),
        .res(jump_address_e)
    );

    assign pc_branch_e = is_jalr_e
        ? {jump_address_e[31:1], 1'b0}
        : jump_address_e;

    assign branch_taken_e = branch_type_e[1]
        ? (branch_type_e[0] ? alu_out_e[0] : ~alu_out_e[0])
        : (alu_equal_e ^ branch_type_e[0]);

    always @(posedge clk) begin
        if (reset) begin

            alu_out_m    <= 32'b0;
            write_data_m <= 32'b0;
            reg_addr_m   <= 5'b0;
            pc_plus4_m   <= 32'b0;

            mem_write_m  <= 1'b0;
            reg_write_m  <= 1'b0;
            mem_to_reg_m  <= 1'b0;
            is_jump_m    <= 1'b0;
            mem_size_m   <= 2'b10;
            load_unsigned_m <= 1'b0;
        end else begin

            alu_out_m    <= alu_out_e;
            write_data_m <= forwarded_b_e;
            reg_addr_m   <= reg_addr_e;
            pc_plus4_m   <= pc_plus4_e;

            mem_write_m  <= mem_write_e;
            reg_write_m  <= reg_write_e;
            mem_to_reg_m  <= mem_to_reg_e;
            is_jump_m    <= is_jump_e;
            mem_size_m   <= mem_size_e;
            load_unsigned_m <= load_unsigned_e;
        end
    end

    // Memory
    DataMemory #(.DATA_FILE(DATA_FILE)) DM (
        .data_addr(alu_out_m),
        .data_write(write_data_m),
        .clk(clk),
        .write_enable(mem_write_m && !reset),
        .mem_size(mem_size_m),
        .load_unsigned(load_unsigned_m),
        .data_read(read_data_m)
    );

    always @(posedge clk) begin
        if (reset) begin

            alu_out_w   <= 32'b0;
            read_data_w <= 32'b0;
            reg_addr_w  <= 5'b0;
            pc_plus4_w  <= 32'b0;

            reg_write_w <= 1'b0;
            mem_to_reg_w <= 1'b0;
            is_jump_w   <= 1'b0;
        end else begin

            alu_out_w   <= alu_out_m;
            read_data_w <= read_data_m;
            reg_addr_w  <= reg_addr_m;
            pc_plus4_w  <= pc_plus4_m;

            reg_write_w <= reg_write_m;
            mem_to_reg_w <= mem_to_reg_m;
            is_jump_w   <= is_jump_m;
        end
    end

    // Writeback
    assign result_w = is_jump_w ? pc_plus4_w : (mem_to_reg_w ? read_data_w : alu_out_w);

endmodule
