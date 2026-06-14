`timescale 1ns/1ps

module packed_int4_dot_product #(
    parameter integer DIM = 16,
    parameter integer ACTIVATION_WIDTH = 8,
    parameter integer ACC_WIDTH = 32,
    parameter integer PACKED_BYTES = (DIM + 1) / 2
) (
    input  logic                                  clk,
    input  logic                                  rst_n,
    input  logic                                  start,
    input  logic [DIM*ACTIVATION_WIDTH-1:0]       activations_flat,
    input  logic [PACKED_BYTES*8-1:0]             packed_weights_flat,
    output logic                                  busy,
    output logic                                  done,
    output logic signed [ACC_WIDTH-1:0]           score,
    output logic [31:0]                           cycle_count,
    output logic [31:0]                           bytes_read
);
    localparam integer INDEX_WIDTH = (DIM <= 1) ? 1 : $clog2(DIM);

    logic [INDEX_WIDTH-1:0] index;
    logic signed [ACC_WIDTH-1:0] accumulator;
    logic signed [ACTIVATION_WIDTH-1:0] activation_value;
    logic [7:0] packed_byte;
    logic signed [3:0] weight_value;
    logic signed [ACTIVATION_WIDTH+3:0] product;

    always_comb begin
        activation_value = $signed(
            activations_flat[index*ACTIVATION_WIDTH +: ACTIVATION_WIDTH]
        );
        packed_byte = packed_weights_flat[(index >> 1)*8 +: 8];
        weight_value = index[0]
            ? $signed(packed_byte[7:4])
            : $signed(packed_byte[3:0]);
        product = activation_value * weight_value;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            index <= '0;
            accumulator <= '0;
            score <= '0;
            busy <= 1'b0;
            done <= 1'b0;
            cycle_count <= '0;
            bytes_read <= '0;
        end else begin
            done <= 1'b0;
            if (start && !busy) begin
                index <= '0;
                accumulator <= '0;
                busy <= 1'b1;
                cycle_count <= '0;
                bytes_read <= DIM * ((ACTIVATION_WIDTH + 7) / 8) + PACKED_BYTES;
            end else if (busy) begin
                cycle_count <= cycle_count + 1'b1;
                if (index == DIM - 1) begin
                    score <= accumulator + product;
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    accumulator <= accumulator + product;
                    index <= index + 1'b1;
                end
            end
        end
    end
endmodule
