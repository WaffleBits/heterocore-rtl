`timescale 1ns/1ps

module int8_matmul_engine_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic start = 1'b0;
    logic activation_write_enable = 1'b0;
    logic [2:0] activation_write_address = '0;
    logic signed [7:0] activation_write_data = '0;
    logic weight_write_enable = 1'b0;
    logic [2:0] weight_write_address = '0;
    logic signed [7:0] weight_write_data = '0;
    logic [1:0] result_read_address = '0;
    logic signed [31:0] result_read_data;
    logic busy;
    logic done;
    logic [31:0] mac_count;
    logic [31:0] cycle_count;

    logic signed [7:0] activation_fixture [0:7];
    logic signed [7:0] weight_fixture [0:7];
    logic signed [31:0] expected [0:3];
    integer index;

    always #5 clk = ~clk;

    int8_matmul_engine dut (.*);

    initial begin
        activation_fixture[0] = 1;
        activation_fixture[1] = 2;
        activation_fixture[2] = 3;
        activation_fixture[3] = 4;
        activation_fixture[4] = -1;
        activation_fixture[5] = 0;
        activation_fixture[6] = 2;
        activation_fixture[7] = 1;

        weight_fixture[0] = 1;
        weight_fixture[1] = 2;
        weight_fixture[2] = 3;
        weight_fixture[3] = 4;
        weight_fixture[4] = 5;
        weight_fixture[5] = 6;
        weight_fixture[6] = 7;
        weight_fixture[7] = 8;

        expected[0] = 50;
        expected[1] = 60;
        expected[2] = 16;
        expected[3] = 18;

        repeat (3) @(posedge clk);
        rst_n <= 1'b1;

        for (index = 0; index < 8; index = index + 1) begin
            @(posedge clk);
            activation_write_enable <= 1'b1;
            activation_write_address <= index[2:0];
            activation_write_data <= activation_fixture[index];
        end
        @(posedge clk);
        activation_write_enable <= 1'b0;

        for (index = 0; index < 8; index = index + 1) begin
            @(posedge clk);
            weight_write_enable <= 1'b1;
            weight_write_address <= index[2:0];
            weight_write_data <= weight_fixture[index];
        end
        @(posedge clk);
        weight_write_enable <= 1'b0;
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        wait (done);
        if (mac_count != 16)
            $fatal(1, "expected 16 MACs, got %0d", mac_count);
        if (cycle_count != 16)
            $fatal(1, "expected 16 compute cycles, got %0d", cycle_count);

        for (index = 0; index < 4; index = index + 1) begin
            result_read_address = index[1:0];
            #1;
            if (result_read_data != expected[index])
                $fatal(
                    1,
                    "result %0d mismatch: expected %0d, got %0d",
                    index,
                    expected[index],
                    result_read_data
                );
        end

        $display(
            "PASS int8 matmul results=[%0d,%0d,%0d,%0d] macs=%0d cycles=%0d",
            expected[0],
            expected[1],
            expected[2],
            expected[3],
            mac_count,
            cycle_count
        );
        $finish;
    end

    initial begin
        #3000;
        $fatal(1, "testbench timeout");
    end
endmodule
