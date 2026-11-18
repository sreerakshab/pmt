`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.06.2026 09:41:42
// Design Name: 
// Module Name: pmt_8
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: parallel_merge_tree_8
//
// Description:
//   PMT(8) - 8-port Parallel Merge-Tree (Song et al., FCCM 2016, Fig. 8).
//
//   Merges 8 sorted input sequences (I0..I7) into one sorted output
//   at up to 8 numbers/cycle.
//
//   Tree structure (3 levels, L = log2(8) = 3):
//
//   Level 1 (MM2):  4 x multirate_merger_2
//     mm2_0: merges I0, I1  -> buf0 (2w wide)
//     mm2_1: merges I2, I3  -> buf1 (2w wide)
//     mm2_2: merges I4, I5  -> buf2 (2w wide)
//     mm2_3: merges I6, I7  -> buf3 (2w wide)
//
//   Level 2 (MM4):  2 x multirate_merger_4
//     mm4_0: merges buf0, buf1 -> buf4 (4w wide)
//     mm4_1: merges buf2, buf3 -> buf5 (4w wide)
//
//   Level 3 (MM8):  1 x multirate_merger_8
//     mm8_0: merges buf4, buf5 -> sorted_out (8w wide)
//
//   Input rate  : 1 number/cycle per input sequence (8 total)
//   Output rate : up to 8 numbers/cycle
//
// Inter-level buffering:
//   Small FIFOs (or the FIFO banks inside each MM) absorb the rate
//   mismatch between levels.  The level-1 outputs (P=2 sorted words/
//   cycle) are directly connected to the level-2 inputs in STREAM mode
//   (fill_mode=0), and similarly for level-2 -> level-3.
//
//   fill_mode for each level:
//     - Level 1 (MM2): fill_mode = top-level fill_mode
//       (caller asserts fill_mode to pre-load the first P=2 words)
//     - Level 2 (MM4): fill_mode = 0 (always streaming from MM2 output)
//     - Level 3 (MM8): fill_mode = 0 (always streaming from MM4 output)
//
// Parameters:
//   WIDTH - data word width in bits (default 16)
//
//////////////////////////////////////////////////////////////////////////////////

module parallel_merge_tree_8 #(
    parameter WIDTH = 16
)(
    input  logic             clk,
    input  logic             rst,

    // fill_mode: assert high for the first fill phase to pre-load all
    // level-1 MM2 FIFOs with their initial sorted sequences.
    // De-assert (0) to enter streaming/merge mode.
    input  logic             fill_mode,

    // in_valid: one pulse per cycle when input data is being presented.
    input  logic             in_valid,

    // 8 input sorted sequences, each providing 1 word/cycle in stream mode.
    // In fill_mode each MM2 receives P=2 words simultaneously via its
    // seq0_in[0..1] / seq1_in[0..1] ports (caller must set both slots).
    input  logic [WIDTH-1:0] seq0_in [2],   // Input sequence 0  -> MM2_0.seq0
    input  logic [WIDTH-1:0] seq1_in [2],   // Input sequence 1  -> MM2_0.seq1
    input  logic [WIDTH-1:0] seq2_in [2],   // Input sequence 2  -> MM2_1.seq0
    input  logic [WIDTH-1:0] seq3_in [2],   // Input sequence 3  -> MM2_1.seq1
    input  logic [WIDTH-1:0] seq4_in [2],   // Input sequence 4  -> MM2_2.seq0
    input  logic [WIDTH-1:0] seq5_in [2],   // Input sequence 5  -> MM2_2.seq1
    input  logic [WIDTH-1:0] seq6_in [2],   // Input sequence 6  -> MM2_3.seq0
    input  logic [WIDTH-1:0] seq7_in [2],   // Input sequence 7  -> MM2_3.seq1

    // Final merged output: up to 8 sorted words per cycle
    output logic [WIDTH-1:0] sorted_out [8],
    output logic             out_valid
);

    // -------------------------------------------------------------------------
    // Level-1: 4 x MM(2)
    //   Each MM2 takes two sorted input sequences (width-1 word/cycle each)
    //   and produces 2 sorted words/cycle.
    // -------------------------------------------------------------------------
    logic [WIDTH-1:0] mm2_out_0 [2], mm2_out_1 [2];
    logic [WIDTH-1:0] mm2_out_2 [2], mm2_out_3 [2];
    logic             mm2_valid_0, mm2_valid_1, mm2_valid_2, mm2_valid_3;

    multirate_merger_2 #(.WIDTH(WIDTH), .P(2)) mm2_0 (
        .clk        (clk),
        .rst        (rst),
        .fill_mode  (fill_mode),
        .in_valid   (in_valid),
        .seq0_in    (seq0_in),
        .seq1_in    (seq1_in),
        .sorted_out (mm2_out_0),
        .out_valid  (mm2_valid_0)
    );

    multirate_merger_2 #(.WIDTH(WIDTH), .P(2)) mm2_1 (
        .clk        (clk),
        .rst        (rst),
        .fill_mode  (fill_mode),
        .in_valid   (in_valid),
        .seq0_in    (seq2_in),
        .seq1_in    (seq3_in),
        .sorted_out (mm2_out_1),
        .out_valid  (mm2_valid_1)
    );

    multirate_merger_2 #(.WIDTH(WIDTH), .P(2)) mm2_2 (
        .clk        (clk),
        .rst        (rst),
        .fill_mode  (fill_mode),
        .in_valid   (in_valid),
        .seq0_in    (seq4_in),
        .seq1_in    (seq5_in),
        .sorted_out (mm2_out_2),
        .out_valid  (mm2_valid_2)
    );

    multirate_merger_2 #(.WIDTH(WIDTH), .P(2)) mm2_3 (
        .clk        (clk),
        .rst        (rst),
        .fill_mode  (fill_mode),
        .in_valid   (in_valid),
        .seq0_in    (seq6_in),
        .seq1_in    (seq7_in),
        .sorted_out (mm2_out_3),
        .out_valid  (mm2_valid_3)
    );

    // -------------------------------------------------------------------------
    // Level-2: 2 x MM(4)
    //   Each MM4 takes two P=2 sorted streams from Level-1 and produces
    //   4 sorted words/cycle.
    //   fill_mode is wired to 0: level-2 is always in streaming mode.
    //   in_valid is the OR of the two feeding MM2 valid signals
    //   (both should be valid simultaneously in a balanced tree).
    // -------------------------------------------------------------------------
    logic [WIDTH-1:0] mm4_out_0 [4], mm4_out_1 [4];
    logic             mm4_valid_0, mm4_valid_1;

    // Pad MM2 2-wide outputs into 4-wide ports for MM4 (upper 2 slots unused
    // in stream mode; MM4 treats them as the P=2 new words at wr_offset).
    // In stream mode MM4 expects P/2 = 2 new words at positions [0] and [1].
    // The MM2 outputs arrive in sorted pairs, which is exactly what MM4 needs.
    logic [WIDTH-1:0] mm4_0_seq0 [4], mm4_0_seq1 [4];
    logic [WIDTH-1:0] mm4_1_seq0 [4], mm4_1_seq1 [4];

    always_comb begin
        // MM4_0 feeds: seq0 <- mm2_out_0, seq1 <- mm2_out_1
        mm4_0_seq0[0] = mm2_out_0[0];
        mm4_0_seq0[1] = mm2_out_0[1];
        mm4_0_seq0[2] = '0;
        mm4_0_seq0[3] = '0;

        mm4_0_seq1[0] = mm2_out_1[0];
        mm4_0_seq1[1] = mm2_out_1[1];
        mm4_0_seq1[2] = '0;
        mm4_0_seq1[3] = '0;

        // MM4_1 feeds: seq0 <- mm2_out_2, seq1 <- mm2_out_3
        mm4_1_seq0[0] = mm2_out_2[0];
        mm4_1_seq0[1] = mm2_out_2[1];
        mm4_1_seq0[2] = '0;
        mm4_1_seq0[3] = '0;

        mm4_1_seq1[0] = mm2_out_3[0];
        mm4_1_seq1[1] = mm2_out_3[1];
        mm4_1_seq1[2] = '0;
        mm4_1_seq1[3] = '0;
    end

    multirate_merger #(.WIDTH(WIDTH), .P(4)) mm4_0 (
        .clk        (clk),
        .rst        (rst),
        .fill_mode  (1'b0),
        .in_valid   (mm2_valid_0 & mm2_valid_1),
        .seq0_in    (mm4_0_seq0),
        .seq1_in    (mm4_0_seq1),
        .sorted_out (mm4_out_0),
        .out_valid  (mm4_valid_0)
    );

    multirate_merger #(.WIDTH(WIDTH), .P(4)) mm4_1 (
        .clk        (clk),
        .rst        (rst),
        .fill_mode  (1'b0),
        .in_valid   (mm2_valid_2 & mm2_valid_3),
        .seq0_in    (mm4_1_seq0),
        .seq1_in    (mm4_1_seq1),
        .sorted_out (mm4_out_1),
        .out_valid  (mm4_valid_1)
    );

    // -------------------------------------------------------------------------
    // Level-3: 1 x MM(8)
    //   Takes two P=4 sorted streams from Level-2 and produces 8 sorted
    //   words/cycle.
    // -------------------------------------------------------------------------
    logic [WIDTH-1:0] mm8_seq0 [8], mm8_seq1 [8];

    always_comb begin
        mm8_seq0[0] = mm4_out_0[0];
        mm8_seq0[1] = mm4_out_0[1];
        mm8_seq0[2] = mm4_out_0[2];
        mm8_seq0[3] = mm4_out_0[3];
        mm8_seq0[4] = '0;
        mm8_seq0[5] = '0;
        mm8_seq0[6] = '0;
        mm8_seq0[7] = '0;

        mm8_seq1[0] = mm4_out_1[0];
        mm8_seq1[1] = mm4_out_1[1];
        mm8_seq1[2] = mm4_out_1[2];
        mm8_seq1[3] = mm4_out_1[3];
        mm8_seq1[4] = '0;
        mm8_seq1[5] = '0;
        mm8_seq1[6] = '0;
        mm8_seq1[7] = '0;
    end

    multirate_merger_8 #(.WIDTH(WIDTH), .P(8)) mm8_0 (
        .clk        (clk),
        .rst        (rst),
        .fill_mode  (1'b0),
        .in_valid   (mm4_valid_0 & mm4_valid_1),
        .seq0_in    (mm8_seq0),
        .seq1_in    (mm8_seq1),
        .sorted_out (sorted_out),
        .out_valid  (out_valid)
    );

endmodule
