module schedule_controller (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        cmd_valid,
    output logic        cmd_ready,
    input  logic        cmd_target_analog,
    input  logic [15:0] cmd_tile_count,
    output logic        analog_start,
    output logic        digital_start,
    output logic [15:0] active_tile_count,
    input  logic        analog_done,
    input  logic        digital_done,
    output logic        busy,
    output logic [31:0] cycle_count,
    output logic [31:0] analog_op_count,
    output logic [31:0] digital_op_count
);
    typedef enum logic [1:0] {
        STATE_IDLE,
        STATE_DISPATCH,
        STATE_WAIT
    } state_t;

    state_t state;
    logic active_target_analog;

    assign cmd_ready = (state == STATE_IDLE);
    assign busy = (state != STATE_IDLE);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            active_target_analog <= 1'b0;
            active_tile_count <= 16'd0;
            analog_start <= 1'b0;
            digital_start <= 1'b0;
            cycle_count <= 32'd0;
            analog_op_count <= 32'd0;
            digital_op_count <= 32'd0;
        end else begin
            analog_start <= 1'b0;
            digital_start <= 1'b0;

            if (busy)
                cycle_count <= cycle_count + 1'b1;

            case (state)
                STATE_IDLE: begin
                    if (cmd_valid) begin
                        active_target_analog <= cmd_target_analog;
                        active_tile_count <= cmd_tile_count;
                        state <= STATE_DISPATCH;
                    end
                end

                STATE_DISPATCH: begin
                    if (active_target_analog)
                        analog_start <= 1'b1;
                    else
                        digital_start <= 1'b1;
                    state <= STATE_WAIT;
                end

                STATE_WAIT: begin
                    if (active_target_analog && analog_done) begin
                        analog_op_count <= analog_op_count + 1'b1;
                        state <= STATE_IDLE;
                    end else if (!active_target_analog && digital_done) begin
                        digital_op_count <= digital_op_count + 1'b1;
                        state <= STATE_IDLE;
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end
endmodule

