`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 11:50:14
// Design Name: 
// Module Name: fifo_bank
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


module fifo_bank #(
    parameter P     = 2,
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input  logic             clk,
    input  logic             rst,
    input  logic [P-1:0]     shift_vec,
    input  logic [P-1:0]     push_vec,
    input  logic [WIDTH-1:0] din      [P],
    output logic [WIDTH-1:0] fifo_out [P],
    output logic [P-1:0]     has_data,
    output logic [$clog2(DEPTH):0] dbg_count [P],
    output logic [WIDTH-1:0]       dbg_mem   [P][DEPTH]
);
    genvar g;
    generate
        for (g = 0; g < P; g++) begin : FIFO_GEN
            narrow_fifo_srl #(.WIDTH(WIDTH), .DEPTH(DEPTH)) fifo_inst (
                .clk      (clk),
                .rst      (rst),
                .shift    (shift_vec[g]),
                .push     (push_vec[g]),
                .din      (din[g]),
                .dout     (fifo_out[g]),
                .has_data (has_data[g]),
                .dbg_count(dbg_count[g]),
                .dbg_mem  (dbg_mem[g])
            );
        end
    endgenerate
endmodule