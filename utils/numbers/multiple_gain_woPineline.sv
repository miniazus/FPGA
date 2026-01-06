//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : multiple_gain
// Date          : January 5, 2026
// Description   : Applies a gain (multiplication) to an array of input signals.
//
//                 Key capabilities:
//                 1. Parallel Processing: Instantiates N multipliers in parallel
//                    using a generate loop.
//                 2. Optimization: Uses conditional generation (if/else) to 
//                    create only the necessary signed/unsigned logic logic 
//                    at elaboration time.
//                 3. Full Precision: Output width is double the input width.
//
// Parameters:
//   DATA_WIDTH : Bit width of the inputs (e.g., 16 bits).
//   NUM_INOUT  : Number of parallel channels to process.
//   IS_SIGNED  : 1 = Signed multiplication (Standard for DSP).
//                0 = Unsigned multiplication.
//
// Inputs:
//   i_data : Array of input signals.
//   i_gain : Array of gain coefficients.
//
// Outputs:
//   o_data : Array of amplified results. Width is DATA_WIDTH*2.
//
// !!! DELAY = 0 (Purely Combinational - Watch timing at high freq!)
//
// Usage Example:
//   multiple_gain_woPineline #(
//       .DATA_WIDTH(16),
//       .NUM_INOUT(4),
//       .IS_SIGNED(1)
//   ) u_gain (
//       .i_clk(sys_clk),
//       .i_ena(1'b1),        // Always enabled
//       .i_rst_n(rst_n),
//       .i_data(adc_data),   // Array of 4 inputs [15:0]
//       .i_gain(gain_coeffs),// Array of 4 gains  [15:0]
//       .o_data(amp_result)  // Array of 4 outputs [31:0]
//   );
//
//////////////////////////////////////////////////////////////////////////////////

module multiple_gain_woPineline #(
    parameter int DATA_WIDTH = 16,
    parameter int NUM_INOUT  = 8,
    parameter bit IS_SIGNED  = 1   // 1=Signed, 0=Unsigned
)(
    input  logic [DATA_WIDTH-1:0]   i_data [NUM_INOUT],
    input  logic [DATA_WIDTH-1:0]   i_gain [NUM_INOUT],
    output logic [DATA_WIDTH*2-1:0] o_data [NUM_INOUT]
);

    generate
        genvar i;
        for (i=0; i<NUM_INOUT; i++) begin : gen_gain
            if (IS_SIGNED) begin : gen_signed
                assign o_data[i] = $signed(i_data[i]) * $signed(i_gain[i]);
            end
            else begin : gen_unsigned
                assign o_data[i] = i_data[i] * i_gain[i];
            end
        end
    endgenerate

endmodule
