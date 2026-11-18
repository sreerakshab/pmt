`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.06.2026 10:14:54
// Design Name: 
// Module Name: multirate_merger
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


module multirate_merger #(
    parameter WIDTH = 16,
    parameter P     = 4
)(
    input  logic             clk,
    input  logic             rst,
    input  logic             fill_mode,         
    input  logic             in_valid,          
    input  logic [WIDTH-1:0] seq0_in [P],
    input  logic [WIDTH-1:0] seq1_in [P],
    output logic [WIDTH-1:0] sorted_out [P],
    output logic             out_valid
);
    logic [P-1:0] s_vector_raw;   
    logic [P-1:0] s_vector;       
    logic [P-1:0] s_fifo0, s_fifo1;
 
    logic [$clog2(P):0]   rate0, rate1;
    logic [$clog2(P)-1:0] offset0, offset1;
 
    logic [WIDTH-1:0] fifo0_out [P], fifo1_out [P];
    logic [WIDTH-1:0] d0 [P], d1 [P];
    logic [P-1:0]     push_vec0, push_vec1;
    logic [WIDTH-1:0] fifo0_din [P], fifo1_din [P];
    logic [P-1:0]     fifo0_has_data, fifo1_has_data;
 
    logic merger_active;
    assign merger_active = (|fifo0_has_data) & (|fifo1_has_data);
 
   assign s_vector = merger_active ? s_vector_raw : '0;  // for BPM/rate converters

always_comb begin
    for (int i = 0; i < P; i++) begin
        automatic int phys0 = (int'(offset0) + i) % P;
        automatic int phys1 = (int'(offset1) + i) % P;
        
        s_fifo0[phys0] = merger_active ? ~s_vector_raw[i]     : 1'b0;
        s_fifo1[phys1] = merger_active ?  s_vector_raw[P-1-i] : 1'b0;
    end
end
logic [$clog2(P)-1:0] wr_offset0, wr_offset1;

always_ff @(posedge clk) begin
    if (rst) begin
        wr_offset0 <= '0;
        wr_offset1 <= '0;
    end else if (in_valid && !fill_mode) begin
        wr_offset0 <= ($clog2(P))'((int'(wr_offset0) + (P/2)) % P);
        wr_offset1 <= ($clog2(P))'((int'(wr_offset1) + (P/2)) % P);
    end
end
 
    rate_converter #(.P(P)) rc0 (
        .clk(clk), .rst(rst), .s_fifo(s_fifo0),
        .rate(rate0), .offset(offset0)
    );
    rate_converter #(.P(P)) rc1 (
        .clk(clk), .rst(rst), .s_fifo(s_fifo1),
        .rate(rate1), .offset(offset1)
    );
 
    input_barrel_shifter #(.WIDTH(WIDTH), .P(P)) ibs0 (
        .offset(wr_offset0), .in_valid(in_valid), .fill_mode(fill_mode),
        .in(seq0_in), .fifo_din(fifo0_din), .fifo_push(push_vec0)
    );
    input_barrel_shifter #(.WIDTH(WIDTH), .P(P)) ibs1 (
        .offset(wr_offset1), .in_valid(in_valid), .fill_mode(fill_mode),
        .in(seq1_in), .fifo_din(fifo1_din), .fifo_push(push_vec1)
    );
 

    logic [$clog2(16):0] fifo0_dbg_count [P], fifo1_dbg_count [P];
    logic [WIDTH-1:0]    fifo0_dbg_mem   [P][16], fifo1_dbg_mem [P][16];
 
    fifo_bank #(.P(P), .WIDTH(WIDTH), .DEPTH(16)) fifo0_bank (
        .clk      (clk),
        .rst      (rst),
        .shift_vec(s_fifo0),
        .push_vec (push_vec0),
        .din      (fifo0_din),
        .fifo_out (fifo0_out),
        .has_data (fifo0_has_data),
        .dbg_count(fifo0_dbg_count),
        .dbg_mem  (fifo0_dbg_mem)
    );
    fifo_bank #(.P(P), .WIDTH(WIDTH), .DEPTH(16)) fifo1_bank (
        .clk      (clk),
        .rst      (rst),
        .shift_vec(s_fifo1),
        .push_vec (push_vec1),
        .din      (fifo1_din),
        .fifo_out (fifo1_out),
        .has_data (fifo1_has_data),
        .dbg_count(fifo1_dbg_count),
        .dbg_mem  (fifo1_dbg_mem)
    );
 
    output_barrel_shifter #(.WIDTH(WIDTH), .P(P)) obs0 (
        .offset(offset0), .fifo_out(fifo0_out), .D(d0)
    );
    output_barrel_shifter #(.WIDTH(WIDTH), .P(P)) obs1 (
        .offset(offset1), .fifo_out(fifo1_out), .D(d1)
    );
 
    bitonic_partial_merger_8to4 #(.WIDTH(WIDTH)) bpm (
        .clk(clk), .merger_active(merger_active),
        .fifo0_data(d0), .fifo1_data(d1),
        .sorted_out(sorted_out), .out_valid(out_valid),
        .s_vector(s_vector_raw)
    );
 
endmodule