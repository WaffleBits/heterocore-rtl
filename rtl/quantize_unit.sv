module quantize_unit #(
    parameter INPUT_WIDTH = 24,
    parameter OUTPUT_WIDTH = 8,
    parameter SHIFT_WIDTH = 5
) (
    input  logic signed [INPUT_WIDTH-1:0] value_in,
    input  logic [SHIFT_WIDTH-1:0]        right_shift,
    output logic signed [OUTPUT_WIDTH-1:0] value_out
);
    logic signed [INPUT_WIDTH-1:0] shifted;
    logic signed [INPUT_WIDTH-1:0] maximum;
    logic signed [INPUT_WIDTH-1:0] minimum;

    always_comb begin
        shifted = value_in >>> right_shift;
        maximum = (1 <<< (OUTPUT_WIDTH - 1)) - 1;
        minimum = -(1 <<< (OUTPUT_WIDTH - 1));
        if (shifted > maximum)
            value_out = maximum[OUTPUT_WIDTH-1:0];
        else if (shifted < minimum)
            value_out = minimum[OUTPUT_WIDTH-1:0];
        else
            value_out = shifted[OUTPUT_WIDTH-1:0];
    end
endmodule

