module analog_array_if (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [15:0] tile_count,
    output logic        request_valid,
    input  logic        request_ready,
    output logic [15:0] request_tile_count,
    input  logic        response_valid,
    output logic        done
);
    logic request_pending;
    logic response_pending;

    assign request_valid = request_pending;
    assign request_tile_count = tile_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            request_pending <= 1'b0;
            response_pending <= 1'b0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;
            if (start) begin
                request_pending <= 1'b1;
                response_pending <= 1'b0;
            end
            if (request_pending && request_ready) begin
                request_pending <= 1'b0;
                response_pending <= 1'b1;
            end
            if (response_pending && response_valid) begin
                response_pending <= 1'b0;
                done <= 1'b1;
            end
        end
    end
endmodule

