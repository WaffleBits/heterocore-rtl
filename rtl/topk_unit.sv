`timescale 1ns/1ps

module topk_unit #(
    parameter integer MAX_K = 4,
    parameter integer ID_WIDTH = 8,
    parameter integer SCORE_WIDTH = 32
) (
    input  logic                              clk,
    input  logic                              rst_n,
    input  logic                              clear,
    input  logic [$clog2(MAX_K+1)-1:0]        requested_k,
    input  logic                              in_valid,
    input  logic                              in_last,
    input  logic [ID_WIDTH-1:0]               in_id,
    input  logic signed [SCORE_WIDTH-1:0]     in_score,
    output logic                              done,
    output logic [MAX_K*ID_WIDTH-1:0]         ids_flat,
    output logic [MAX_K*SCORE_WIDTH-1:0]      scores_flat,
    output logic [$clog2(MAX_K+1)-1:0]        valid_count
);
    localparam logic signed [SCORE_WIDTH-1:0] MIN_SCORE = {
        1'b1, {(SCORE_WIDTH-1){1'b0}}
    };

    logic signed [SCORE_WIDTH-1:0] scores [0:MAX_K-1];
    logic [ID_WIDTH-1:0] ids [0:MAX_K-1];
    integer item_count;
    integer insert_position;
    integer index;

    always_comb begin
        insert_position = MAX_K;
        for (index = 0; index < MAX_K; index = index + 1)
            if (
                insert_position == MAX_K
                && (
                    in_score > scores[index]
                    || (in_score == scores[index] && in_id < ids[index])
                )
            )
                insert_position = index;

        for (index = 0; index < MAX_K; index = index + 1) begin
            ids_flat[index*ID_WIDTH +: ID_WIDTH] = ids[index];
            scores_flat[index*SCORE_WIDTH +: SCORE_WIDTH] = scores[index];
        end
        valid_count = item_count < requested_k
            ? item_count[$clog2(MAX_K+1)-1:0]
            : requested_k;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 1'b0;
            item_count <= 0;
            for (index = 0; index < MAX_K; index = index + 1) begin
                scores[index] <= MIN_SCORE;
                ids[index] <= {ID_WIDTH{1'b1}};
            end
        end else begin
            done <= 1'b0;
            if (clear) begin
                item_count <= 0;
                for (index = 0; index < MAX_K; index = index + 1) begin
                    scores[index] <= MIN_SCORE;
                    ids[index] <= {ID_WIDTH{1'b1}};
                end
            end else if (in_valid) begin
                if (insert_position < MAX_K) begin
                    for (index = MAX_K - 1; index > 0; index = index - 1)
                        if (index > insert_position) begin
                            scores[index] <= scores[index-1];
                            ids[index] <= ids[index-1];
                        end
                    scores[insert_position] <= in_score;
                    ids[insert_position] <= in_id;
                end
                if (item_count < MAX_K)
                    item_count <= item_count + 1;
                if (in_last)
                    done <= 1'b1;
            end
        end
    end
endmodule
