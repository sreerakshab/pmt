`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.06.2026 10:29:26
// Design Name: 
// Module Name: bitonic_merger_4to2
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


module bitonic_merger_4to2 #(
    parameter WIDTH = 8
)(
    input  logic             clk,
    input  logic             merger_active,   
    input  logic [WIDTH-1:0] fifo0_data [0:1],
    input  logic [WIDTH-1:0] fifo1_data [0:1],
    output logic [WIDTH-1:0] sorted_out [0:1],
    output logic             out_valid,       
    output logic [1:0]       s_vector
);
    logic [WIDTH-1:0] stg1_out [0:1];
    logic [WIDTH-1:0] stg1_reg [0:1];
    logic             active_r1;

    cas_unit #(.WIDTH(WIDTH)) cas_0 (
        .a(fifo0_data[0]), .b(fifo1_data[1]),
        .max_out(stg1_out[0]), .sel_b(s_vector[0])
    );
    cas_unit #(.WIDTH(WIDTH)) cas_1 (
        .a(fifo0_data[1]), .b(fifo1_data[0]),
        .max_out(stg1_out[1]), .sel_b(s_vector[1])
    );

    always_ff @(posedge clk) begin
        stg1_reg  <= stg1_out;
        active_r1 <= merger_active;
    end

    cae_desc #(.WIDTH(WIDTH)) cae_0 (
        .a(stg1_reg[0]), .b(stg1_reg[1]),
        .out0(sorted_out[0]), .out1(sorted_out[1])
    );

    assign out_valid = active_r1;

endmodule