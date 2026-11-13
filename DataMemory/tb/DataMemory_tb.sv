`timescale 1ns/1ps

module tb_DataMemory;
    reg [31:0] data_addr;
    reg [31:0] data_write;
    reg clk;
    reg write_enable;
    reg [1:0] mem_size;
    reg load_unsigned;
    wire [31:0] data_read;

    reg [7:0] expected_bytes [0:4095];
    reg [31:0] rand_val;
    reg [31:0] random_address;
    reg [1:0] random_size;

    integer errors;
    integer tests;
    integer random_tests;
    integer i, j, k;

    DataMemory dut (
        .data_addr(data_addr),
        .data_write(data_write),
        .clk(clk),
        .write_enable(write_enable),
        .mem_size(mem_size),
        .load_unsigned(load_unsigned),
        .data_read(data_read)
    );

    initial begin
        clk = 0;
        forever
            #2 clk = ~clk;
    end

    function access_allowed;
        input [31:0] address;
        input [1:0] size;
        begin
            access_allowed = 1'b0;
            if (address < 32'd4096) begin
                case (size)
                    2'b00: access_allowed = 1'b1;
                    2'b01: access_allowed = (address % 2 == 0);
                    2'b10: access_allowed = (address % 4 == 0);
                    default: access_allowed = 1'b0;
                endcase
            end
        end
    endfunction

    task memory_write;
        input [31:0] address;
        input [31:0] data;
        input [1:0] size;
        integer byte_count;
        integer b;
        begin
            @(negedge clk);
            data_addr = address;
            data_write = data;
            mem_size = size;
            load_unsigned = 1'b0;
            write_enable = 1'b1;

            #1;
            tests = tests + 1;
            if (data_read !== 32'b0) begin
                errors = errors + 1;
                $display("WRITE FAIL: read output must be zero, address=%h", address);
            end

            @(posedge clk);
            #1;
            if (access_allowed(address, size)) begin
                byte_count = 1 << size;
                for(b=0; b<byte_count; b=b+1)
                    expected_bytes[address + b] = (data >> (8 * b));
            end

            write_enable = 1'b0;
        end
    endtask

    task memory_read_expected;
        input [31:0] address;
        input [1:0] size;
        input unsigned_load;
        input [31:0] expected;
        begin
            data_addr = address;
            mem_size = size;
            load_unsigned = unsigned_load;
            write_enable = 1'b0;
            #1;

            tests = tests + 1;
            if (data_read !== expected) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("READ FAIL: address=%h size=%b unsigned=%b data=%h expected=%h",
                             address, size, unsigned_load, data_read, expected);
            end
        end
    endtask

    task memory_read_check;
        input [31:0] address;
        input [1:0] size;
        input unsigned_load;
        reg [31:0] expected;
        integer byte_count;
        integer b;
        begin
            expected = 32'b0;
            if (access_allowed(address, size)) begin
                byte_count = 1 << size;
                for(b=0; b<byte_count; b=b+1)
                    expected = expected | ({24'b0, expected_bytes[address + b]} << (8 * b));

                if (!unsigned_load) begin
                    if (size == 2'b00 && expected[7])
                        expected = expected | 32'hFFFFFF00;
                    if (size == 2'b01 && expected[15])
                        expected = expected | 32'hFFFF0000;
                end
            end
            memory_read_expected(address, size, unsigned_load, expected);
        end
    endtask

    initial begin
        if ($test$plusargs("waves")) begin
            $dumpfile("build/vcd/DataMemory/DataMemory.vcd");
            $dumpvars(0, tb_DataMemory);
        end

        data_addr = 32'b0;
        data_write = 32'b0;
        write_enable = 1'b0;
        mem_size = 2'b10;
        load_unsigned = 1'b0;
        errors = 0;
        tests = 0;

        if (!$value$plusargs("random_tests=%d", random_tests))
            random_tests = 200000;
        if (random_tests < 0)
            $fatal(1, "random_tests must be nonnegative");

        memory_read_expected(0, 2'b10, 1'b0, 32'h00500093);
        memory_read_expected(4092, 2'b10, 1'b0, 32'h00000013);

        // Initialize every word through the public write port.
        for(i=0; i<1024; i=i+1) begin
            rand_val = $urandom;
            memory_write(i * 4, rand_val, 2'b10);
        end

        // All byte addresses, signednesses, and supported sizes.
        for(i=0; i<4096; i=i+1) begin
            memory_read_check(i, 2'b00, 1'b0);
            memory_read_check(i, 2'b00, 1'b1);
            memory_read_check(i, 2'b01, 1'b0);
            memory_read_check(i, 2'b01, 1'b1);
            memory_read_check(i, 2'b10, 1'b0);
            memory_read_check(i, 2'b10, 1'b1);
        end

        for(i=0; i<256; i=i+1) begin
            for(j=0; j<4; j=j+1) begin
                memory_write(j, 32'hABCDEF00 | i, 2'b00);
                memory_read_check(j, 2'b00, 1'b0);
                memory_read_check(j, 2'b00, 1'b1);
                memory_read_check(0, 2'b10, 1'b0);
            end
        end

        for(j=0; j<4; j=j+2) begin
            for(k=0; k<6; k=k+1) begin
                case (k)
                    0: rand_val = 32'hABCD0000;
                    1: rand_val = 32'hABCD7FFF;
                    2: rand_val = 32'hABCD8000;
                    3: rand_val = 32'hABCDFFFF;
                    4: rand_val = 32'hABCD00FF;
                    5: rand_val = 32'hABCDFF00;
                endcase
                memory_write(j, rand_val, 2'b01);
                memory_read_check(j, 2'b01, 1'b0);
                memory_read_check(j, 2'b01, 1'b1);
                memory_read_check(0, 2'b10, 1'b0);
            end
        end

        repeat(random_tests) begin
            random_address = $urandom_range(4095, 0);
            random_size = $urandom_range(2, 0);
            if (random_size == 2'b01)
                random_address = random_address & 32'hFFFFFFFE;
            if (random_size == 2'b10)
                random_address = random_address & 32'hFFFFFFFC;

            memory_write(random_address, $urandom, random_size);
            memory_read_check(random_address, random_size, 1'b0);
            memory_read_check(random_address, random_size, 1'b1);
            memory_read_check(random_address & 32'hFFFFFFFC, 2'b10, 1'b0);
            memory_read_check((random_address & 32'hFFFFFFFC) ^ 32'd4, 2'b10, 1'b0);
        end

        // Disabled writes preserve all words of the memory array.
        for(i=0; i<1024; i=i+1) begin
            @(negedge clk);
            data_addr = i * 4;
            data_write = $urandom;
            mem_size = i % 3;
            write_enable = 1'b0;
            @(posedge clk);
            #1;
            memory_read_check(i * 4, 2'b10, 1'b0);
        end

        // last legal byte and halfword.
        memory_write(4095, 32'hA5, 2'b00);
        memory_read_check(4095, 2'b00, 1'b0);
        memory_read_check(4095, 2'b00, 1'b1);
        memory_write(4094, 32'h8001, 2'b01);
        memory_read_check(4094, 2'b01, 1'b0);
        memory_read_check(4094, 2'b01, 1'b1);

        // invalid stores must not silently alias a valid word.
        memory_write(1, 32'hDEADBEEF, 2'b01);
        memory_write(2, 32'hDEADBEEF, 2'b10);
        memory_write(4095, 32'hDEADBEEF, 2'b01);
        memory_write(4094, 32'hDEADBEEF, 2'b10);
        memory_write(0, 32'hDEADBEEF, 2'b11);
        memory_write(4096, 32'hDEADBEEF, 2'b10);
        memory_write(32'hFFFFF000, 32'hDEADBEEF, 2'b10);
        memory_read_check(0, 2'b11, 1'b0);
        memory_read_check(4096, 2'b10, 1'b0);
        memory_read_check(32'hFFFFF000, 2'b10, 1'b0);

        // a full final comparison catches stray/corrupting stores.
        for(i=0; i<1024; i=i+1)
            memory_read_check(i * 4, 2'b10, 1'b0);

        if ($test$plusargs("waves"))
            $writememh("build/vcd/DataMemory/data_result.hex", dut.memory);

        if (errors == 0)
            $display("PASS: %0d checks, %0d random stores", tests, random_tests);
        else
            $fatal(1, "FAIL: %0d errors", errors);

        $finish;
    end
endmodule
