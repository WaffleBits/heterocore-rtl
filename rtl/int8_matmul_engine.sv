module int8_matmul_engine #(
    parameter M = 2,
    parameter K = 4,
    parameter N = 2,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32,
    localparam ACTIVATION_ADDR_WIDTH = (M * K <= 1) ? 1 : $clog2(M * K),
    localparam WEIGHT_ADDR_WIDTH = (K * N <= 1) ? 1 : $clog2(K * N),
    localparam RESULT_ADDR_WIDTH = (M * N <= 1) ? 1 : $clog2(M * N)
) (
    input  logic                               clk,
    input  logic                               rst_n,
    input  logic                               start,
    input  logic                               activation_write_enable,
    input  logic [ACTIVATION_ADDR_WIDTH-1:0]   activation_write_address,
    input  logic signed [DATA_WIDTH-1:0]       activation_write_data,
    input  logic                               weight_write_enable,
    input  logic [WEIGHT_ADDR_WIDTH-1:0]       weight_write_address,
    input  logic signed [DATA_WIDTH-1:0]       weight_write_data,
    input  logic [RESULT_ADDR_WIDTH-1:0]       result_read_address,
    output logic signed [ACC_WIDTH-1:0]        result_read_data,
    output logic                               busy,
    output logic                               done,
    output logic [31:0]                        mac_count,
    output logic [31:0]                        cycle_count
);
    localparam M_INDEX_WIDTH = (M <= 1) ? 1 : $clog2(M);
    localparam K_INDEX_WIDTH = (K <= 1) ? 1 : $clog2(K);
    localparam N_INDEX_WIDTH = (N <= 1) ? 1 : $clog2(N);

    logic signed [DATA_WIDTH-1:0] activations [0:M*K-1];
    logic signed [DATA_WIDTH-1:0] weights [0:K*N-1];
    logic signed [ACC_WIDTH-1:0] results [0:M*N-1];
    logic [M_INDEX_WIDTH-1:0] m_index;
    logic [K_INDEX_WIDTH-1:0] k_index;
    logic [N_INDEX_WIDTH-1:0] n_index;
    logic signed [ACC_WIDTH-1:0] accumulator;
    logic signed [(DATA_WIDTH*2)-1:0] product;

    always_comb begin
        product = activations[m_index * K + k_index]
            * weights[k_index * N + n_index];
        result_read_data = results[result_read_address];
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
            m_index <= '0;
            k_index <= '0;
            n_index <= '0;
            accumulator <= '0;
            mac_count <= 32'd0;
            cycle_count <= 32'd0;
        end else begin
            done <= 1'b0;

            if (!busy) begin
                if (activation_write_enable)
                    activations[activation_write_address] <= activation_write_data;
                if (weight_write_enable)
                    weights[weight_write_address] <= weight_write_data;
            end

            if (start && !busy) begin
                busy <= 1'b1;
                m_index <= '0;
                k_index <= '0;
                n_index <= '0;
                accumulator <= '0;
                mac_count <= 32'd0;
                cycle_count <= 32'd0;
            end else if (busy) begin
                cycle_count <= cycle_count + 1'b1;
                mac_count <= mac_count + 1'b1;
                if (k_index == K - 1) begin
                    results[m_index * N + n_index] <= accumulator + product;
                    accumulator <= '0;
                    k_index <= '0;
                    if (n_index == N - 1) begin
                        n_index <= '0;
                        if (m_index == M - 1) begin
                            m_index <= '0;
                            busy <= 1'b0;
                            done <= 1'b1;
                        end else begin
                            m_index <= m_index + 1'b1;
                        end
                    end else begin
                        n_index <= n_index + 1'b1;
                    end
                end else begin
                    accumulator <= accumulator + product;
                    k_index <= k_index + 1'b1;
                end
            end
        end
    end
endmodule
