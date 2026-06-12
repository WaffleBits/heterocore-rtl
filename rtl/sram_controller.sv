module sram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10
) (
    input  logic                  clk,
    input  logic                  write_enable,
    input  logic [ADDR_WIDTH-1:0] write_address,
    input  logic [DATA_WIDTH-1:0] write_data,
    input  logic                  read_enable,
    input  logic [ADDR_WIDTH-1:0] read_address,
    output logic [DATA_WIDTH-1:0] read_data,
    output logic                  read_valid
);
    localparam DEPTH = 1 << ADDR_WIDTH;
    logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    always_ff @(posedge clk) begin
        read_valid <= read_enable;
        if (write_enable)
            memory[write_address] <= write_data;
        if (read_enable)
            read_data <= memory[read_address];
    end
endmodule

