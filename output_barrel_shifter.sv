`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.06.2026 10:14:03
// Design Name: 
// Module Name: output_barrel_shifter
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


module output_barrel_shifter #(
    parameter WIDTH = 8,
    parameter P     = 4
)(
    input  logic [$clog2(P)-1:0] offset,        
    input  logic [WIDTH-1:0]     fifo_out [P],
    output logic [WIDTH-1:0]     D [P]
);
    always_comb begin
        for (int i = 0; i < P; i++) begin
            automatic int idx = (int'(offset) + i) % P;
            D[i] = fifo_out[idx];
        end
    end
endmodule
