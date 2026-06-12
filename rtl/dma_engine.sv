module dma_engine #(
    parameter DATA_WIDTH = 32,
    parameter LENGTH_WIDTH = 16
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    start,
    input  logic [LENGTH_WIDTH-1:0] length_words,
    input  logic [DATA_WIDTH-1:0]   source_data,
    input  logic                    source_valid,
    output logic                    source_ready,
    output logic [DATA_WIDTH-1:0]   stream_data,
    output logic                    stream_valid,
    input  logic                    stream_ready,
    output logic                    busy,
    output logic                    done
);
    logic [LENGTH_WIDTH-1:0] remaining;

    assign stream_data = source_data;
    assign stream_valid = busy && source_valid;
    assign source_ready = busy && stream_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            remaining <= '0;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;
            if (start && !busy) begin
                remaining <= length_words;
                busy <= (length_words != 0);
                done <= (length_words == 0);
            end else if (stream_valid && stream_ready) begin
                if (remaining == 1) begin
                    remaining <= '0;
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    remaining <= remaining - 1'b1;
                end
            end
        end
    end
endmodule

