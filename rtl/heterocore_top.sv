module heterocore_top (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        cmd_valid,
    output logic        cmd_ready,
    input  logic        cmd_target_analog,
    input  logic [15:0] cmd_tile_count,
    output logic        analog_request_valid,
    input  logic        analog_request_ready,
    output logic [15:0] analog_request_tile_count,
    input  logic        analog_response_valid,
    output logic        digital_start,
    input  logic        digital_done,
    output logic        busy,
    output logic [31:0] cycle_count,
    output logic [31:0] analog_op_count,
    output logic [31:0] digital_op_count
);
    logic analog_start;
    logic analog_done;
    logic [15:0] active_tile_count;

    schedule_controller controller (
        .clk(clk),
        .rst_n(rst_n),
        .cmd_valid(cmd_valid),
        .cmd_ready(cmd_ready),
        .cmd_target_analog(cmd_target_analog),
        .cmd_tile_count(cmd_tile_count),
        .analog_start(analog_start),
        .digital_start(digital_start),
        .active_tile_count(active_tile_count),
        .analog_done(analog_done),
        .digital_done(digital_done),
        .busy(busy),
        .cycle_count(cycle_count),
        .analog_op_count(analog_op_count),
        .digital_op_count(digital_op_count)
    );

    analog_array_if array_interface (
        .clk(clk),
        .rst_n(rst_n),
        .start(analog_start),
        .tile_count(active_tile_count),
        .request_valid(analog_request_valid),
        .request_ready(analog_request_ready),
        .request_tile_count(analog_request_tile_count),
        .response_valid(analog_response_valid),
        .done(analog_done)
    );
endmodule

