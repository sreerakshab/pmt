`timescale 1ns / 1ps

module bitonic_partial_merger_16to8 #(
    parameter WIDTH = 16
)(
    input  logic             clk,
    input  logic             merger_active,
    input  logic [WIDTH-1:0] fifo0_data [0:7],
    input  logic [WIDTH-1:0] fifo1_data [0:7],
    output logic [WIDTH-1:0] sorted_out [0:7],
    output logic             out_valid,
    output logic [7:0]       s_vector
);

  
    logic [WIDTH-1:0] stg1_out [0:7];
    logic [7:0]       sv1;

    genvar i;
    generate
        for (i = 0; i < 8; i++) begin : CAS_STG1
            cas_unit #(.WIDTH(WIDTH)) cas_i (
                .a      (fifo0_data[i]),
                .b      (fifo1_data[7-i]),
                .max_out(stg1_out[i]),
                .sel_b  (sv1[i])
            );
        end
    endgenerate

    assign s_vector = sv1;

    logic [WIDTH-1:0] stg1_reg [0:7];
    logic             active_r1;

    always_ff @(posedge clk) begin
        stg1_reg  <= stg1_out;
        active_r1 <= merger_active;
    end

    logic [WIDTH-1:0] stg2_out [0:7];

    generate
        for (i = 0; i < 4; i++) begin : CAE_STG2
            cae_desc #(.WIDTH(WIDTH)) cae_pair (
                .a   (stg1_reg[i]),
                .b   (stg1_reg[i+4]),
                .out0(stg2_out[i]),
                .out1(stg2_out[i+4])
            );
        end
    endgenerate

    logic [WIDTH-1:0] stg2_reg [0:7];
    logic             active_r2;

    always_ff @(posedge clk) begin
        stg2_reg  <= stg2_out;
        active_r2 <= active_r1;
    end

    logic [WIDTH-1:0] s3a [0:7];
    logic [WIDTH-1:0] s3b [0:7];
    logic [WIDTH-1:0] s3c [0:7];
    logic [WIDTH-1:0] s3d [0:7];
    logic [WIDTH-1:0] s3e [0:7];
    logic [WIDTH-1:0] s3f [0:7];

    generate
        for (i = 0; i < 4; i++) begin : CAE_S3A
            cae_desc #(.WIDTH(WIDTH)) u (
                .a   (stg2_reg[i*2]),
                .b   (stg2_reg[i*2+1]),
                .out0(s3a[i*2]),
                .out1(s3a[i*2+1])
            );
        end
    endgenerate

    always_comb begin
        s3b[0] = s3a[0];
        s3b[7] = s3a[7];
    end
    generate
        for (i = 0; i < 3; i++) begin : CAE_S3B
            cae_desc #(.WIDTH(WIDTH)) u (
                .a   (s3a[i*2+1]),
                .b   (s3a[i*2+2]),
                .out0(s3b[i*2+1]),
                .out1(s3b[i*2+2])
            );
        end
    endgenerate

    generate
        for (i = 0; i < 4; i++) begin : CAE_S3C
            cae_desc #(.WIDTH(WIDTH)) u (
                .a   (s3b[i*2]),
                .b   (s3b[i*2+1]),
                .out0(s3c[i*2]),
                .out1(s3c[i*2+1])
            );
        end
    endgenerate

    generate
        for (i = 0; i < 2; i++) begin : CAE_S3D
            cae_desc #(.WIDTH(WIDTH)) u_lo (
                .a   (s3c[i]),
                .b   (s3c[i+2]),
                .out0(s3d[i]),
                .out1(s3d[i+2])
            );
            cae_desc #(.WIDTH(WIDTH)) u_hi (
                .a   (s3c[i+4]),
                .b   (s3c[i+6]),
                .out0(s3d[i+4]),
                .out1(s3d[i+6])
            );
        end
    endgenerate

    always_comb begin
        s3e[0] = s3d[0];
        s3e[7] = s3d[7];
    end
    generate
        for (i = 0; i < 3; i++) begin : CAE_S3E
            cae_desc #(.WIDTH(WIDTH)) u (
                .a   (s3d[i*2+1]),
                .b   (s3d[i*2+2]),
                .out0(s3e[i*2+1]),
                .out1(s3e[i*2+2])
            );
        end
    endgenerate

    generate
        for (i = 0; i < 4; i++) begin : CAE_S3F
            cae_desc #(.WIDTH(WIDTH)) u (
                .a   (s3e[i*2]),
                .b   (s3e[i*2+1]),
                .out0(s3f[i*2]),
                .out1(s3f[i*2+1])
            );
        end
    endgenerate

    logic active_r3;

    always_ff @(posedge clk) begin
        sorted_out <= s3f;
        active_r3  <= active_r2;
    end

    assign out_valid = active_r3;

endmodule