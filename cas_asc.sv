`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2026 18:49:13
// Design Name: 
// Module Name: cas_asc
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


module cas_unit #(parameter WIDTH = 8)(
    input  logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] max_out,
    output logic             sel_b
);
    always_comb begin
        if (b > a) begin max_out = b; sel_b = 1'b1; end
        else       begin max_out = a; sel_b = 1'b0; end
    end
endmodule