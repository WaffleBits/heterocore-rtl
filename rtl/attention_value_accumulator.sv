`timescale 1ns/1ps

module attention_value_accumulator #(
    parameter integer TOKENS = 4,
    parameter integer DIM = 8,
    parameter integer WEIGHT_WIDTH = 8,
    parameter integer VALUE_WIDTH = 8,
    parameter integer ACC_WIDTH = 32
) (
    input  logic                                  clk,
    input  logic                                  rst_n,
    input  logic                                  start,
    input  logic [TOKENS*WEIGHT_WIDTH-1:0]        weights_flat,
    input  logic [TOKENS*DIM*VALUE_WIDTH-1:0]     values_flat,
    output logic                                  busy,
    output logic                                  done,
    output logic [DIM*ACC_WIDTH-1:0]              output_flat,
    output logic [31:0]                           cycle_count,
    output logic [31:0]                           bytes_read
);
    localparam integer TOKEN_INDEX_WIDTH = (TOKENS <= 1) ? 1 : $clog2(TOKENS);
    localparam integer DIM_INDEX_WIDTH = (DIM <= 1) ? 1 : $clog2(DIM);

    logic [TOKEN_INDEX_WIDTH-1:0] token_index;
    logic [DIM_INDEX_WIDTH-1:0] dimension_index;
    logic signed [ACC_WIDTH-1:0] accumulator;
    logic signed [WEIGHT_WIDTH-1:0] weight_value;
    logic signed [VALUE_WIDTH-1:0] value;
    logic signed [WEIGHT_WIDTH+VALUE_WIDTH-1:0] product;

    always_comb begin
        weight_value = $signed(
            weights_flat[token_index*WEIGHT_WIDTH +: WEIGHT_WIDTH]
        );
        value = $signed(
            values_flat[
                ((token_index*DIM + dimension_index)*VALUE_WIDTH) +: VALUE_WIDTH
            ]
        );
        product = weight_value * value;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_index <= '0;
            dimension_index <= '0;
            accumulator <= '0;
            output_flat <= '0;
            busy <= 1'b0;
            done <= 1'b0;
            cycle_count <= '0;
            bytes_read <= '0;
        end else begin
            done <= 1'b0;
            if (start && !busy) begin
                token_index <= '0;
                dimension_index <= '0;
                accumulator <= '0;
                output_flat <= '0;
                busy <= 1'b1;
                cycle_count <= '0;
                bytes_read <= (
                    TOKENS * ((WEIGHT_WIDTH + 7) / 8)
                    + TOKENS * DIM * ((VALUE_WIDTH + 7) / 8)
                );
            end else if (busy) begin
                cycle_count <= cycle_count + 1'b1;
                if (token_index == TOKENS - 1) begin
                    output_flat[
                        dimension_index*ACC_WIDTH +: ACC_WIDTH
                    ] <= accumulator + product;
                    accumulator <= '0;
                    token_index <= '0;
                    if (dimension_index == DIM - 1) begin
                        dimension_index <= '0;
                        busy <= 1'b0;
                        done <= 1'b1;
                    end else begin
                        dimension_index <= dimension_index + 1'b1;
                    end
                end else begin
                    accumulator <= accumulator + product;
                    token_index <= token_index + 1'b1;
                end
            end
        end
    end
endmodule
