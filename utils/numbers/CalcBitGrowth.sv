//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : Calc Bit Growth
// Date          : November 24, 2025
// Description   : Calculates the required output bit width for a summation
//                 operation based on the number of active inputs.
//
//                 The module performs the following steps:
//                 1. Counts the number of active inputs (set bits) in 'i_input_enable'.
//                 2. Calculates the bit growth required (ceil(log2(active_count))).
//                 3. Adds the growth bits to the original signal width (ORI_WIDTH).
//
// Parameters:
//   NUM_INPUT      : Maximum number of inputs (width of the enable vector).
//   ORI_WIDTH      : The bit width of the original signals being summed.
//
// Inputs:
//   i_input_enable   : Binary mask where each bit represents an active input signal.
//
// Outputs:
//   o_width          : The calculated total width required to avoid overflow.
//
// !!! DELAY = 1
//
// Using:
// CalcBitGrowth #(.NUM_INPUT(...), .ORI_WIDTH(...))
//                (.i_input_enable(...), .o_width(...));
//
//////////////////////////////////////////////////////////////////////////////////

module CalcBitGrowth #(
    parameter int NUM_INPUT = 8,
    parameter int ORI_WIDTH = 16
)(
    input  logic i_clk, i_rst_n,
    input  logic [NUM_INPUT-1:0] i_input_enable,
    output logic [7:0]           o_width
);

    logic [$clog2(NUM_INPUT+1)-1:0] counted_ones;
    logic [$clog2(NUM_INPUT+1)-1:0] num_add_bit;


    always_ff @ (posedge i_clk) begin
        if (i_rst_n == 0) begin
            counted_ones <= '0;
        end
        else begin
            // Step A: Hardware Bit Counter
            counted_ones <= $countones(i_input_enable);
        end
    end

    always_comb begin
        // Step B: Loop to find Log2 (Priority Encoder logic)
        num_add_bit = 0; // Default value

        for (int i = 0; i < $clog2(NUM_INPUT); i++) begin
            if (counted_ones > (1 << i)) begin
                num_add_bit = i + 1;
            end
        end

        // Step C: Add to base width
        o_width = num_add_bit + ORI_WIDTH;
    end

endmodule
