`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 11:49:20
// Design Name: 
// Module Name: narrow_fifo_srl
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


module narrow_fifo_srl #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input  logic             clk,
    input  logic             rst,
    input  logic             shift,
    input  logic             push,
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout,
    output logic             has_data,
    output logic [$clog2(DEPTH):0]  dbg_count,
    output logic [WIDTH-1:0]        dbg_mem [0:DEPTH-1]
);
    logic [WIDTH-1:0]       mem   [0:DEPTH-1];
    logic [$clog2(DEPTH):0] count;
 
    assign dbg_count = count;
    assign dbg_mem   = mem;
 
    assign has_data = (count > 0);
    assign dout     = has_data ? mem[count-1] : '0;
 
    always_ff @(posedge clk) begin
        if (rst) begin
            count <= '0;
        end else begin
            if (push) begin
                for (int i = DEPTH-1; i > 0; i--)
                    mem[i] <= mem[i-1];
                mem[0] <= din;
            end
 
            if      ( push && !shift && count < DEPTH) count <= count + 1;
            else if (!push &&  shift && count > 0)     count <= count - 1;
         
        end
    end
endmodule