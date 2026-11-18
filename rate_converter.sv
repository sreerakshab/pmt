`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 11:51:20
// Design Name: 
// Module Name: rate_converter
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


module rate_converter #(
    parameter P = 2
)(
    input  logic                 clk,
    input  logic                 rst,
    input  logic [P-1:0]         s_fifo,        
    output logic [$clog2(P):0]   rate,       
    output logic [$clog2(P)-1:0] offset          
);
    logic [P:0] m;  
 
    always_comb begin
    rate = 0;

    for(int i=0;i<P;i++)
        rate += s_fifo[i];
end
 
    always_ff @(posedge clk) begin
        if (rst) offset <= '0;
        else     offset <= ($clog2(P))'((int'(offset) + int'(rate)) % P);
    end
 
endmodule