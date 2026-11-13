`timescale 1ns/1ps

module CU32bit (
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,

    // Immediate Generator control:
    output reg [2:0] immd_type,

    // ALU control:
    output reg [2:0] alu_control,
    output reg alu_variant,
    output reg alu_src,
    output reg is_lui,
    output reg is_auipc,

    // Branch and jump control:
    output reg is_branch,
    output reg [1:0] branch_type,
    output reg is_jump,
    output reg is_jalr,

    // Memory and write back control:
    output reg mem_write,
    output reg reg_write,
    output reg mem_to_reg,
    output reg [1:0] mem_size,
    output reg load_unsigned
);

    always @* begin
        immd_type   = 3'b000;
        alu_control = 3'b000;
        alu_variant = 1'b0;
        alu_src     = 1'b0;
        is_lui      = 1'b0;
        is_auipc    = 1'b0;
        is_branch   = 1'b0;
        branch_type = 2'b00;
        is_jump     = 1'b0;
        is_jalr     = 1'b0;
        mem_write   = 1'b0;
        reg_write   = 1'b0;
        mem_to_reg  = 1'b0;
        mem_size    = 2'b10;
        load_unsigned = 1'b0;

        case (opcode)
            // Register-register arithmetic and logic.
            7'b0110011: begin
                case ({funct7, funct3})
                    10'b0000000_000: begin // ADD
                        alu_control = 3'b000;
                        reg_write = 1'b1;
                    end
                    10'b0100000_000: begin // SUB
                        alu_control = 3'b000;
                        alu_variant = 1'b1;
                        reg_write = 1'b1;
                    end
                    10'b0000000_001: begin // SLL
                        alu_control = 3'b101;
                        reg_write = 1'b1;
                    end
                    10'b0000000_010: begin // SLT
                        alu_control = 3'b110;
                        alu_variant = 1'b1;
                        reg_write = 1'b1;
                    end
                    10'b0000000_011: begin // SLTU
                        alu_control = 3'b111;
                        alu_variant = 1'b1;
                        reg_write = 1'b1;
                    end
                    10'b0000000_100: begin // XOR
                        alu_control = 3'b100;
                        reg_write = 1'b1;
                    end
                    10'b0000000_101: begin // SRL
                        alu_control = 3'b001;
                        reg_write = 1'b1;
                    end
                    10'b0100000_101: begin // SRA
                        alu_control = 3'b001;
                        alu_variant = 1'b1;
                        reg_write = 1'b1;
                    end
                    10'b0000000_110: begin // OR
                        alu_control = 3'b011;
                        reg_write = 1'b1;
                    end
                    10'b0000000_111: begin // AND
                        alu_control = 3'b010;
                        reg_write = 1'b1;
                    end
                    default: begin end
                endcase
            end

            // Register-immediate arithmetic and logic (I-type).
            7'b0010011: begin
                alu_src = 1'b1;
                case (funct3)
                    3'b000: begin // ADDI
                        alu_control = 3'b000;
                        reg_write = 1'b1;
                    end
                    3'b010: begin // SLTI
                        alu_control = 3'b110;
                        alu_variant = 1'b1;
                        reg_write = 1'b1;
                    end
                    3'b011: begin // SLTIU
                        alu_control = 3'b111;
                        alu_variant = 1'b1;
                        reg_write = 1'b1;
                    end
                    3'b100: begin // XORI
                        alu_control = 3'b100;
                        reg_write = 1'b1;
                    end
                    3'b110: begin // ORI
                        alu_control = 3'b011;
                        reg_write = 1'b1;
                    end
                    3'b111: begin // ANDI
                        alu_control = 3'b010;
                        reg_write = 1'b1;
                    end
                    3'b001: begin // SLLI
                        if (funct7 == 7'b0000000) begin
                            alu_control = 3'b101;
                            reg_write = 1'b1;
                        end
                    end
                    3'b101: begin // SRLI / SRAI
                        if (funct7 == 7'b0000000) begin
                            alu_control = 3'b001;
                            reg_write = 1'b1;
                        end else if (funct7 == 7'b0100000) begin
                            alu_control = 3'b001;
                            alu_variant = 1'b1;
                            reg_write = 1'b1;
                        end
                    end
                    default: begin end
                endcase
            end

            7'b0000011: begin // Loads (I-type)
                case (funct3)
                    // LB, LH, LW, LBU, LHU
                    3'b000, 3'b001, 3'b010, 3'b100, 3'b101: begin
                        alu_src = 1'b1;
                        reg_write = 1'b1;
                        mem_to_reg = 1'b1;
                        mem_size = funct3[1:0];
                        load_unsigned = funct3[2];
                    end
                    default: begin end
                endcase
            end

            7'b0100011: begin // Stores (S-type)
                case (funct3)
                    // SB, SH, SW
                    3'b000, 3'b001, 3'b010: begin
                        immd_type = 3'b001;
                        alu_src = 1'b1;
                        mem_write = 1'b1;
                        mem_size = funct3[1:0];
                    end
                    default: begin end
                endcase
            end

            7'b1100011: begin // Conditional branches (B-type)
                immd_type = 3'b010;
                case (funct3)
                    3'b000: begin // BEQ
                        is_branch = 1'b1;
                        branch_type = 2'b00;
                    end
                    3'b001: begin // BNE
                        is_branch = 1'b1;
                        branch_type = 2'b01;
                    end
                    3'b100: begin // BLT
                        is_branch = 1'b1;
                        branch_type = 2'b11;
                        alu_control = 3'b110;
                        alu_variant = 1'b1;
                    end
                    3'b101: begin // BGE
                        is_branch = 1'b1;
                        branch_type = 2'b10;
                        alu_control = 3'b110;
                        alu_variant = 1'b1;
                    end
                    3'b110: begin // BLTU
                        is_branch = 1'b1;
                        branch_type = 2'b11;
                        alu_control = 3'b111;
                        alu_variant = 1'b1;
                    end
                    3'b111: begin // BGEU
                        is_branch = 1'b1;
                        branch_type = 2'b10;
                        alu_control = 3'b111;
                        alu_variant = 1'b1;
                    end
                    default: begin end
                endcase
            end

            7'b1101111: begin // JAL (J-type)
                immd_type = 3'b100;
                is_jump = 1'b1;
                reg_write = 1'b1;
            end

            7'b1100111: begin // JALR (I-type)
                if (funct3 == 3'b000) begin
                    alu_src = 1'b1;
                    is_jump = 1'b1;
                    is_jalr = 1'b1;
                    reg_write = 1'b1;
                end
            end

            7'b0110111: begin // LUI (U-type)
                immd_type = 3'b011;
                alu_src = 1'b1;
                is_lui = 1'b1;
                reg_write = 1'b1;
            end

            7'b0010111: begin // AUIPC (U-type)
                immd_type = 3'b011;
                alu_src = 1'b1;
                is_auipc = 1'b1;
                reg_write = 1'b1;
            end

            default: begin end
        endcase
    end

endmodule
