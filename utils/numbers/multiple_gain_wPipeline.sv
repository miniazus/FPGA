//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : multiple_gain_with_Pipeline
// Date          : January 5, 2026
// Description   : Applies a gain to input signals with output registering.
//
//                 Key capabilities:
//                 1. High Performance: Infers DSP slices with output registers
//                    (M-REG), suitable for high-frequency operation.
//                 2. Synchronous Reset: Clears outputs cleanly on clock edge.
//                 3. Full Precision: Output width is double the input width.
//
// Parameters:
//   DATA_WIDTH : Bit width of the inputs.
//   NUM_INOUT  : Number of parallel channels.
//   IS_SIGNED  : 1 = Signed (DSP), 0 = Unsigned.
//
// Inputs:
//   i_clk      : System Clock.
//   i_ena      : Clock Enable (Control the pipeline).
//   i_rst_n    : Synchronous Reset (Active Low).
//   i_data/gain: Input arrays.
//
// Outputs:
//   o_data : Registered output arrays.
//
// !!! DELAY = 1 (1 Clock Cycle Latency)
//
// Usage Example:
//   multiple_gain_wPipeline #(
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

module multiple_gain_wPipeline #(
    parameter int DATA_WIDTH = 16,
    parameter int NUM_INOUT  = 8,
    parameter bit IS_SIGNED  = 1
)(
    input  logic i_clk, i_ena, i_rst_n,
    input  logic [DATA_WIDTH-1:0]   i_data [NUM_INOUT],
    input  logic [DATA_WIDTH-1:0]   i_gain [NUM_INOUT],
    output logic [DATA_WIDTH*2-1:0] o_data [NUM_INOUT]
);

    generate
        genvar i;
        for (i=0; i<NUM_INOUT; i++) begin : gen_gain

            always_ff @ (posedge i_clk) begin
                if (!i_rst_n) begin
                    o_data[i] <= '0;
                end
                else if (i_ena) begin
                    // The synthesis tool removes the unused branch automatically
                    if (IS_SIGNED) begin
                        o_data[i] <= $signed(i_data[i]) * $signed(i_gain[i]);
                    end
                    else begin
                        o_data[i] <= i_data[i] * i_gain[i];
                    end
                end
            end
        end
    endgenerate

endmodule
