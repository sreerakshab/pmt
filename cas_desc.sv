`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2026 19:07:42
// Design Name: 
// Module Name: cas_desc
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


module cae_desc #(parameter WIDTH = 8)(
    input  logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] out0, out1
);
    always_comb begin
        if (a >= b) begin out0 = a; out1 = b; end
        else        begin out0 = b; out1 = a; end
    end
endmodule