//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : MultiInputAdderWithRounding
// Description   : This module performs addition of multiple signed or unsigned 
//                 input values and applies unbiased rounding (round-half-to-even) 
//                 to the result. The output can be truncated to a smaller width 
//                 with optional saturation. Fractional inputs can be handled 
//                 correctly with symmetric rounding.
//
// Parameters:
//   NUM_INPUT   : Number of input values to sum
//   WIDTH_IN    : Bit width of each input value
//   WIDTH_OUT   : Bit width of the output after rounding
//   IS_SIGNED   : 0 = unsigned input/output, 1 = signed input/output
//   IS_FRACTION : 0 = integer mode, 1 = fractional mode
//
// Inputs:
//   clk  : Clock signal for synchronous output updates
//   ena  : Enable signal to update the output
//   din  : Array of NUM_INPUT signed or unsigned inputs of WIDTH_IN bits
//
// Outputs:
//   dout : Rounded sum of the inputs, WIDTH_OUT bits wide
//
// Features:
//   - Multi-input addition
//   - Unbiased rounding (round-half-to-even) with optional fractional support
//   - Handles signed and unsigned arithmetic
//   - Saturation on rounding overflow
//   - Synthesizable for FPGA/ASIC
//////////////////////////////////////////////////////////////////////////////////

module MultiInputAdderWithRounding #(
    parameter int NUM_INPUT     = 2,
    parameter int WIDTH_IN      = 0,
    parameter int WIDTH_OUT     = 0,
    parameter bit IS_SIGNED     = 1,      // 0 = unsigned, 1 = signed
    parameter bit IS_FRACTION   = 0       // 0 = integer, 1 = fractional
)
(
    input  logic clk, ena,
    input  logic signed [WIDTH_IN -1:0] din [NUM_INPUT],
    output logic signed [WIDTH_OUT-1:0] dout
);

    localparam int WIDTHTEMP = WIDTH_IN + $clog2(NUM_INPUT);

    // Check parameter validity
    if (WIDTH_IN <= 0) begin : gen_error_DATA_WIDTH_IN
        initial begin
            $error("DATA_WIDTH_IN must be > 0");
        end
    end


    logic signed [WIDTHTEMP-1:0]   d_tem;
    MultiInputAdder #(.NUM_INPUT(NUM_INPUT), .WIDTH_IN(WIDTH_IN))
                    (.clk(clk), .ena(ena), .din(din), .dout(d_tem));


    logic signed [WIDTH_OUT-1:0]   d_tem_rounded;
    UnbiasedRounding #( .WIDTH_IN(WIDTHTEMP),
                        .WIDTH_OUT(WIDTH_OUT),
                        .IS_SIGNED(IS_SIGNED),
                        .IS_FRACTION(IS_FRACTION))
                    (.clk(clk), .ena(ena), .din(d_tem), .dout(d_tem_rounded));

    assign dout = d_tem_rounded;

endmodule
