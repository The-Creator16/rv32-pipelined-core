`timescale 1ns/1ps

module tb_Performance;
    reg clk = 0;
    reg reset = 1;
    // Shadow validity distinguishes real instructions (including NOPs/stores/
    // branches) from injected bubbles. No production RTL changes are needed.
    reg valid_d = 0, valid_e = 0, valid_m = 0, valid_w = 0;
    reg [31:0] pc_d, pc_e, pc_m, pc_w;
    reg [31:0] instruction_d, instruction_e, instruction_m, instruction_w;
    reg [31:0] expected_pc [0:1023];
    reg [31:0] expected_instruction [0:1023];
    reg [31:0] expected_rd [0:1023];
    reg [31:0] expected_value [0:1023];
    reg [31:0] expected_memory [0:1023];
    reg [31:0] expected_store_address [0:1023];
    reg [31:0] expected_store_value [0:1023];
    string name, program_path, prefix, output_path;
    integer expected_count, expected_stores, words, stop_pc;
    integer cycles = 0, retired = 0, stalls = 0;
    integer branches = 0, taken = 0, misses = 0, predictions = 0;
    integer jumps = 0, redirects = 0, flush_d_cycles = 0, flush_e_cycles = 0;
    integer forward_mem_operands = 0, forward_wb_operands = 0;
    integer stores = 0, i, trace_file, result_file;
    reg uses_a, uses_b;

    CPU32bit #(.PROGRAM_FILE("Performance/programs/01_independent.hex"),
               .DATA_FILE("Performance/programs/data.hex")) dut (
        .clk(clk), .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        if (!$value$plusargs("name=%s", name) ||
            !$value$plusargs("count=%d", expected_count) ||
            !$value$plusargs("stores=%d", expected_stores) ||
            !$value$plusargs("words=%d", words) ||
            !$value$plusargs("stop=%d", stop_pc))
            $fatal(1, "Missing benchmark arguments");
        prefix = {"Performance/programs/", name};
        #1; // After IM's time-zero initializer; before the first active edge.
        $readmemh({prefix, ".hex"}, dut.IM.memory);
        $readmemh({prefix, ".pc.hex"}, expected_pc, 0, expected_count-1);
        $readmemh({prefix, ".instr.hex"}, expected_instruction, 0, expected_count-1);
        $readmemh({prefix, ".rd.hex"}, expected_rd, 0, expected_count-1);
        $readmemh({prefix, ".value.hex"}, expected_value, 0, expected_count-1);
        $readmemh({prefix, ".memory.hex"}, expected_memory);
        if (expected_stores > 0) begin
            $readmemh({prefix, ".store_addr.hex"}, expected_store_address, 0, expected_stores-1);
            $readmemh({prefix, ".store_value.hex"}, expected_store_value, 0, expected_stores-1);
        end
        trace_file = $fopen({"Performance/results/", name, ".trace.csv"}, "w");
        if (!trace_file) $fatal(1, "Cannot open trace");
        $fdisplay(trace_file, "cycle,pc_f,valid_d,pc_d,valid_e,pc_e,valid_m,pc_m,valid_w,pc_w,stall,predict_taken,mispredict,jump,flush_d,flush_e");
        if ($test$plusargs("waves")) begin
            $dumpfile({"Performance/results/", name, ".vcd"});
            $dumpvars(0, tb_Performance);
        end
        repeat(2) @(negedge clk);
        #1;
        reset = 0;
    end

    always @(posedge clk) begin
        if (reset) begin
            valid_d = 0; valid_e = 0; valid_m = 0; valid_w = 0;
            pc_d = 0; pc_e = 0; pc_m = 0; pc_w = 0;
        end else begin
            // Read DUT before nonblocking updates. RF has already committed
            // the current WB instruction on the preceding falling edge.
            cycles = cycles + 1;
            if (cycles > 2000) $fatal(1, "Timeout");
            $fdisplay(trace_file, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
                cycles, dut.instr_addr_out_f, valid_d, pc_d, valid_e, pc_e,
                valid_m, pc_m, valid_w, pc_w, dut.stall_f, dut.predict_taken_d,
                dut.branch_mispredict_e, dut.is_jump_e, dut.flush_d, dut.flush_e);
            if (dut.stall_f) stalls = stalls + 1;
            if (dut.flush_d) flush_d_cycles = flush_d_cycles + 1;
            if (dut.flush_e) flush_e_cycles = flush_e_cycles + 1;
            if (valid_d && dut.predict_taken_d) predictions = predictions + 1;
            if (valid_e) begin
                if (dut.is_branch_e) begin
                    branches = branches + 1;
                    if (dut.branch_taken_e) taken = taken + 1;
                    if (dut.branch_mispredict_e) misses = misses + 1;
                end
                if (dut.is_jump_e) jumps = jumps + 1;
                if (dut.redirect_e) redirects = redirects + 1;
                uses_a = (instruction_e[6:0] == 7'h13) || (instruction_e[6:0] == 7'h33) ||
                         (instruction_e[6:0] == 7'h03) || (instruction_e[6:0] == 7'h23) ||
                         (instruction_e[6:0] == 7'h63) || (instruction_e[6:0] == 7'h67);
                uses_b = (instruction_e[6:0] == 7'h33) || (instruction_e[6:0] == 7'h23) ||
                         (instruction_e[6:0] == 7'h63);
                if (uses_a && dut.forward_a_m) forward_mem_operands = forward_mem_operands + 1;
                else if (uses_a && dut.forward_a_w) forward_wb_operands = forward_wb_operands + 1;
                if (uses_b && dut.forward_b_m) forward_mem_operands = forward_mem_operands + 1;
                else if (uses_b && dut.forward_b_w) forward_wb_operands = forward_wb_operands + 1;
            end
            if (dut.mem_write_m) begin
                if (!valid_m || stores >= expected_stores) $fatal(1, "Unexpected store");
                if (dut.alu_out_m !== expected_store_address[stores] ||
                    dut.write_data_m !== expected_store_value[stores])
                    $fatal(1, "Store mismatch at PC %h", pc_m);
                stores = stores + 1;
            end
            if (valid_w) begin
                if (retired >= expected_count) $fatal(1, "Extra retirement");
                if (pc_w !== expected_pc[retired] || instruction_w !== expected_instruction[retired])
                    $fatal(1, "Retirement %0d: PC %h expected %h", retired, pc_w, expected_pc[retired]);
                if (expected_rd[retired] != 0) begin
                    if (!dut.reg_write_w || dut.reg_addr_w !== expected_rd[retired][4:0] ||
                        dut.result_w !== expected_value[retired] ||
                        dut.RF.q[expected_rd[retired]] !== expected_value[retired])
                        $fatal(1, "Register result mismatch at PC %h", pc_w);
                end else if (dut.reg_write_w && dut.reg_addr_w != 0)
                    $fatal(1, "Unexpected register write at PC %h", pc_w);
                retired = retired + 1;
                if (pc_w == stop_pc) begin
                    if (retired != expected_count || stores != expected_stores)
                        $fatal(1, "Incorrect retirement/store counts");
                    for(i=0; i<1024; i=i+1) begin
                        if (dut.DM.memory[i] !== expected_memory[i])
                            $fatal(1, "Memory mismatch at word %0d", i);
                    end
                    if (dut.RF.q[0] !== 0) $fatal(1, "x0 corrupted");
                    // Specific to these streams and this ID-predict/EX-resolve core.
                    if (cycles != retired + 4 + stalls + branches + misses + 2*jumps)
                        $fatal(1, "Cycle accounting identity failed");
                    result_file = $fopen({"Performance/results/", name, ".csv"}, "w");
                    if (!result_file) $fatal(1, "Cannot open result");
                    $fdisplay(result_file, "name,cycles,retired,cpi,load_use_stalls,branches,taken,mispredictions,predictions,jumps,redirects,flush_d_cycles,flush_e_cycles,forward_mem_operands,forward_wb_operands,stores");
                    $fdisplay(result_file, "%s,%0d,%0d,%.6f,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
                        name, cycles, retired, $itor(cycles)/retired, stalls, branches, taken,
                        misses, predictions, jumps, redirects, flush_d_cycles, flush_e_cycles,
                        forward_mem_operands, forward_wb_operands, stores);
                    $fclose(result_file);
                    $fclose(trace_file);
                    $display("PASS %s cycles=%0d retired=%0d CPI=%.6f stalls=%0d branches=%0d misses=%0d jumps=%0d",
                        name, cycles, retired, $itor(cycles)/retired, stalls, branches, misses, jumps);
                    $finish;
                end
            end
            // Reverse order preserves old-stage values with blocking assignments.
            valid_w = valid_m; pc_w = pc_m; instruction_w = instruction_m;
            valid_m = valid_e; pc_m = pc_e; instruction_m = instruction_e;
            valid_e = dut.flush_e ? 0 : valid_d;
            pc_e = pc_d; instruction_e = instruction_d;
            if (dut.flush_d) valid_d = 0;
            else if (!dut.stall_d) begin
                valid_d = (dut.instr_addr_out_f < words*4);
                pc_d = dut.instr_addr_out_f;
                instruction_d = dut.instr_f;
            end
        end
    end
endmodule
