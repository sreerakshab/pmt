`timescale 1ns / 1ps

module tb_pmt8;

    localparam WIDTH = 16;
    localparam CLK_PERIOD = 10;

    logic             clk;
    logic             rst;
    logic             fill_mode;
    logic             in_valid;
    logic [WIDTH-1:0] seq0_in [2], seq1_in [2], seq2_in [2], seq3_in [2];
    logic [WIDTH-1:0] seq4_in [2], seq5_in [2], seq6_in [2], seq7_in [2];
    logic [WIDTH-1:0] sorted_out [8];
    logic             out_valid;

    parallel_merge_tree_8 #(.WIDTH(WIDTH)) dut (
        .clk(clk), .rst(rst), .fill_mode(fill_mode), .in_valid(in_valid),
        .seq0_in(seq0_in), .seq1_in(seq1_in), .seq2_in(seq2_in), .seq3_in(seq3_in),
        .seq4_in(seq4_in), .seq5_in(seq5_in), .seq6_in(seq6_in), .seq7_in(seq7_in),
        .sorted_out(sorted_out), .out_valid(out_valid)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    task drive_inputs(
        input logic [WIDTH-1:0] s0[2], input logic [WIDTH-1:0] s1[2],
        input logic [WIDTH-1:0] s2[2], input logic [WIDTH-1:0] s3[2],
        input logic [WIDTH-1:0] s4[2], input logic [WIDTH-1:0] s5[2],
        input logic [WIDTH-1:0] s6[2], input logic [WIDTH-1:0] s7[2]
    );
        begin
            seq0_in = s0; seq1_in = s1; seq2_in = s2; seq3_in = s3;
            seq4_in = s4; seq5_in = s5; seq6_in = s6; seq7_in = s7;
            in_valid = 1;
            @(posedge clk);
            in_valid = 0;
        end
    endtask

    initial begin
        rst = 1; fill_mode = 0; in_valid = 0;
        repeat(3) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // --- Phase 1: Symmetric Fill Mode ---
        // By making pairs identical (0/1 matches 2/3 matches 4/5 matches 6/7)
        // the tree remains perfectly synchronized.
        $display("[%0t] Starting Phase 1: Fill Mode", $time);
        fill_mode = 1;
        drive_inputs(
            '{16'd10, 16'd20}, '{16'd15, 16'd25}, // MM2_0
            '{16'd10, 16'd20}, '{16'd15, 16'd25}, // MM2_1
            '{16'd10, 16'd20}, '{16'd15, 16'd25}, // MM2_2
            '{16'd10, 16'd20}, '{16'd15, 16'd25}  // MM2_3
        );
        fill_mode = 0;
        
        repeat(15) @(posedge clk);

        // --- Phase 2: Symmetric Stream Burst ---
        $display("[%0t] Starting Phase 2: Stream Burst", $time);
        
        drive_inputs(
            '{16'd30, 16'd40}, '{16'd35, 16'd45}, '{16'd30, 16'd40}, '{16'd35, 16'd45},
            '{16'd30, 16'd40}, '{16'd35, 16'd45}, '{16'd30, 16'd40}, '{16'd35, 16'd45}
        );
        drive_inputs(
            '{16'd50, 16'd60}, '{16'd55, 16'd65}, '{16'd50, 16'd60}, '{16'd55, 16'd65},
            '{16'd50, 16'd60}, '{16'd55, 16'd65}, '{16'd50, 16'd60}, '{16'd55, 16'd65}
        );
        drive_inputs(
            '{16'd70, 16'd80}, '{16'd75, 16'd85}, '{16'd70, 16'd80}, '{16'd75, 16'd85},
            '{16'd70, 16'd80}, '{16'd75, 16'd85}, '{16'd70, 16'd80}, '{16'd75, 16'd85}
        );

        // Wait for out_valid (will exit cleanly around 800ns if it fails)
        begin
            int timeout = 0;
            while (!out_valid && timeout < 50) begin
                @(posedge clk);
                timeout++;
            end
        end

        if (out_valid) begin
            $display("[%0t] SUCCESS: Valid Output Received!", $time);
            for (int i = 0; i < 8; i++) begin
                 $display("  sorted_out[%0d] = %d", i, sorted_out[i]);
            end
        end else begin
            $display("[%0t] ERROR: Pipeline Deadlocked.", $time);
        end

        repeat(5) @(posedge clk);
        $finish;
    end
endmodule