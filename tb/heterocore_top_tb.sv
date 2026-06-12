`timescale 1ns/1ps

module heterocore_top_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic cmd_valid = 1'b0;
    logic cmd_ready;
    logic cmd_target_analog = 1'b0;
    logic [15:0] cmd_tile_count = 16'd0;
    logic analog_request_valid;
    logic analog_request_ready = 1'b1;
    logic [15:0] analog_request_tile_count;
    logic analog_response_valid = 1'b0;
    logic digital_start;
    logic digital_done = 1'b0;
    logic busy;
    logic [31:0] cycle_count;
    logic [31:0] analog_op_count;
    logic [31:0] digital_op_count;

    always #5 clk = ~clk;

    heterocore_top dut (.*);

    task send_command(input logic analog_target, input logic [15:0] tiles);
        begin
            @(posedge clk);
            while (!cmd_ready)
                @(posedge clk);
            cmd_target_analog <= analog_target;
            cmd_tile_count <= tiles;
            cmd_valid <= 1'b1;
            @(posedge clk);
            cmd_valid <= 1'b0;
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst_n <= 1'b1;

        send_command(1'b1, 16'd8);
        wait (analog_request_valid);
        if (analog_request_tile_count != 16'd8)
            $fatal(1, "analog tile count mismatch");
        @(posedge clk);
        analog_response_valid <= 1'b1;
        @(posedge clk);
        analog_response_valid <= 1'b0;
        wait (!busy);

        send_command(1'b0, 16'd3);
        wait (digital_start);
        @(posedge clk);
        digital_done <= 1'b1;
        @(posedge clk);
        digital_done <= 1'b0;
        wait (!busy);

        if (analog_op_count != 1)
            $fatal(1, "expected one analog operation");
        if (digital_op_count != 1)
            $fatal(1, "expected one digital operation");
        if (cycle_count == 0)
            $fatal(1, "cycle counter did not advance");

        $display(
            "PASS cycles=%0d analog_ops=%0d digital_ops=%0d",
            cycle_count,
            analog_op_count,
            digital_op_count
        );
        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "testbench timeout");
    end
endmodule

