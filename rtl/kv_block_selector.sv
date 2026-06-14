module kv_block_selector #(
    parameter integer DIM = 16,
    parameter integer NUM_BLOCKS = 8,
    parameter integer MAX_K = 4,
    parameter integer DATA_WIDTH = 8,
    parameter integer SCORE_WIDTH = 32,
    parameter integer ID_WIDTH = (NUM_BLOCKS <= 2) ? 1 : $clog2(NUM_BLOCKS)
) (
    input  logic                                      clk,
    input  logic                                      rst_n,
    input  logic                                      start,
    input  logic [$clog2(MAX_K+1)-1:0]                requested_k,
    input  logic [DIM*DATA_WIDTH-1:0]                 query_flat,
    input  logic [NUM_BLOCKS*DIM*DATA_WIDTH-1:0]      summaries_flat,
    output logic                                      busy,
    output logic                                      done,
    output logic [MAX_K*ID_WIDTH-1:0]                 selected_ids_flat,
    output logic [MAX_K*SCORE_WIDTH-1:0]              selected_scores_flat,
    output logic [$clog2(MAX_K+1)-1:0]                selected_count,
    output logic [31:0]                               cycle_count,
    output logic [31:0]                               bytes_read
);
    localparam integer DIM_INDEX_WIDTH = (DIM <= 1) ? 1 : $clog2(DIM);
    localparam integer BLOCK_INDEX_WIDTH = (NUM_BLOCKS <= 2) ? 1 : $clog2(NUM_BLOCKS);

    typedef enum logic [1:0] {IDLE, SCORE_BLOCK, PUSH_SCORE, WAIT_TOPK} state_t;
    state_t state;
    logic [DIM_INDEX_WIDTH-1:0] dim_index;
    logic [BLOCK_INDEX_WIDTH-1:0] block_index;
    logic signed [SCORE_WIDTH-1:0] accumulator;
    logic signed [SCORE_WIDTH-1:0] pending_score;
    logic signed [DATA_WIDTH-1:0] query_value;
    logic signed [DATA_WIDTH-1:0] summary_value;
    logic signed [(2*DATA_WIDTH)-1:0] product;
    logic topk_done;

    always_comb begin
        query_value = $signed(query_flat[dim_index*DATA_WIDTH +: DATA_WIDTH]);
        summary_value = $signed(
            summaries_flat[((block_index*DIM + dim_index)*DATA_WIDTH) +: DATA_WIDTH]
        );
        product = query_value * summary_value;
    end

    topk_unit #(
        .MAX_K(MAX_K),
        .ID_WIDTH(ID_WIDTH),
        .SCORE_WIDTH(SCORE_WIDTH)
    ) topk (
        .clk(clk),
        .rst_n(rst_n),
        .clear(start && state == IDLE),
        .requested_k(requested_k),
        .in_valid(state == PUSH_SCORE),
        .in_last(state == PUSH_SCORE && block_index == NUM_BLOCKS - 1),
        .in_id(block_index),
        .in_score(pending_score),
        .done(topk_done),
        .ids_flat(selected_ids_flat),
        .scores_flat(selected_scores_flat),
        .valid_count(selected_count)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            dim_index <= '0;
            block_index <= '0;
            accumulator <= '0;
            pending_score <= '0;
            busy <= 1'b0;
            done <= 1'b0;
            cycle_count <= '0;
            bytes_read <= '0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: if (start) begin
                    state <= SCORE_BLOCK;
                    dim_index <= '0;
                    block_index <= '0;
                    accumulator <= '0;
                    busy <= 1'b1;
                    cycle_count <= '0;
                    bytes_read <= DIM * ((DATA_WIDTH + 7) / 8);
                end
                SCORE_BLOCK: begin
                    cycle_count <= cycle_count + 1'b1;
                    bytes_read <= bytes_read + ((DATA_WIDTH + 7) / 8);
                    if (dim_index == DIM - 1) begin
                        pending_score <= accumulator + product;
                        dim_index <= '0;
                        state <= PUSH_SCORE;
                    end else begin
                        accumulator <= accumulator + product;
                        dim_index <= dim_index + 1'b1;
                    end
                end
                PUSH_SCORE: begin
                    cycle_count <= cycle_count + 1'b1;
                    accumulator <= '0;
                    if (block_index == NUM_BLOCKS - 1)
                        state <= WAIT_TOPK;
                    else begin
                        block_index <= block_index + 1'b1;
                        state <= SCORE_BLOCK;
                    end
                end
                WAIT_TOPK: begin
                    cycle_count <= cycle_count + 1'b1;
                    if (topk_done) begin
                        busy <= 1'b0;
                        done <= 1'b1;
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
