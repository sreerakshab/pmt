`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.06.2026 10:12:59
// Design Name: 
// Module Name: input_barrel_shifter
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


module input_barrel_shifter #(
    parameter WIDTH = 8,
    parameter P     = 2
)(
    input  logic [$clog2(P)-1:0] offset,
    input  logic                 in_valid,
    input  logic                 fill_mode,       
    input  logic [WIDTH-1:0]     in [P],
    output logic [WIDTH-1:0]     fifo_din  [P],
    output logic [P-1:0]         fifo_push
);
    localparam int HALF = P / 2;
 
    always_comb begin
        for (int i = 0; i < P; i++) begin
            fifo_din[i]  = '0;
            fifo_push[i] = 1'b0;
        end
        if (in_valid) begin
            if (fill_mode) begin
                for (int i = 0; i < P; i++) begin
                    fifo_din[i]  = in[i];
                    fifo_push[i] = 1'b1;
                end
            end else begin
                for (int i = 0; i < HALF; i++) begin
                    automatic int idx = (int'(offset) + i) % P;
                    fifo_din[idx]  = in[i];
                    fifo_push[idx] = 1'b1;
                end
            end
        end
    end
endmodule