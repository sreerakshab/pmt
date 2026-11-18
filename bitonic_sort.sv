`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2026 19:08:51
// Design Name: 
// Module Name: bitonic_sort
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


module bitonic_partial_merger_8to4 #(
    parameter WIDTH = 8
)(
    input  logic             clk,
    input  logic             merger_active,
    input  logic [WIDTH-1:0] fifo0_data [0:3],
    input  logic [WIDTH-1:0] fifo1_data [0:3],
    output logic [WIDTH-1:0] sorted_out [0:3],
    output logic             out_valid,
    output logic [3:0]       s_vector            // raw combinational, gated externally
);
    // Stage 1: CAS (purely combinational)
    logic [WIDTH-1:0] stg1_out [0:3];
 
    cas_unit #(.WIDTH(WIDTH)) cas_0 (.a(fifo0_data[0]), .b(fifo1_data[3]), .max_out(stg1_out[0]), .sel_b(s_vector[0]));
    cas_unit #(.WIDTH(WIDTH)) cas_1 (.a(fifo0_data[1]), .b(fifo1_data[2]), .max_out(stg1_out[1]), .sel_b(s_vector[1]));
    cas_unit #(.WIDTH(WIDTH)) cas_2 (.a(fifo0_data[2]), .b(fifo1_data[1]), .max_out(stg1_out[2]), .sel_b(s_vector[2]));
    cas_unit #(.WIDTH(WIDTH)) cas_3 (.a(fifo0_data[3]), .b(fifo1_data[0]), .max_out(stg1_out[3]), .sel_b(s_vector[3]));
 
    // Stage 1?2 pipeline register
    logic [WIDTH-1:0] stg1_reg [0:3];
    logic             valid_s2,valid_s3;
    always_ff @(posedge clk) begin
        stg1_reg <= stg1_out;
        valid_s2 <= merger_active;
    end
 
    // Stage 2: CAE descending - pairs (0,2) and (1,3)
    logic [WIDTH-1:0] stg2_out [0:3];
    cae_desc #(.WIDTH(WIDTH)) cae2_0 (.a(stg1_reg[0]), .b(stg1_reg[2]), .out0(stg2_out[0]), .out1(stg2_out[2]));
    cae_desc #(.WIDTH(WIDTH)) cae2_1 (.a(stg1_reg[1]), .b(stg1_reg[3]), .out0(stg2_out[1]), .out1(stg2_out[3]));
 
    // Stage 2?3 pipeline register
    logic [WIDTH-1:0] stg2_reg [0:3];
    always_ff @(posedge clk) begin
        stg2_reg <= stg2_out;
        valid_s3 <= valid_s2;
    end
    assign out_valid = valid_s3;
 
    // Stage 3: CAE descending - adjacent pairs (0,1) and (2,3)
    cae_desc #(.WIDTH(WIDTH)) cae3_0 (.a(stg2_reg[0]), .b(stg2_reg[1]), .out0(sorted_out[0]), .out1(sorted_out[1]));
    cae_desc #(.WIDTH(WIDTH)) cae3_1 (.a(stg2_reg[2]), .b(stg2_reg[3]), .out0(sorted_out[2]), .out1(sorted_out[3]));
 
endmodule