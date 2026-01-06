//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : simple_mux
// Date          : January 5, 2026
// Description   : A fully parameterized N-to-1 Multiplexer.
//
//                 Key capabilities:
//                 1. Efficiency: Uses direct array indexing to infer the most
//                    optimal multiplexing logic (LUTs) during synthesis.
//                 2. Safety: Automatically handles out-of-bounds selection
//                    during simulation (returns 'X') and synthesis (treats as
//                    "Don't Care" for logic minimization).
//                 3. Flexibility: Supports arbitrary data widths and input counts
//                    (including non-power-of-2 sizes).
//
// Parameters:
//   DATA_WIDTH : Bit width of the input/output signals.
//   NUM_INPUT  : Number of input channels.
//
// Inputs:
//   i_data : Packed array of input signals [NUM_INPUT] x [DATA_WIDTH].
//   i_sel  : Selection index. Width is automatically calculated.
//
// Outputs:
//   o_data : The selected data channel.
//
// !!! DELAY = 0 (Purely Combinational)
//
// Usage Example:
//   simple_mux #(
//       .DATA_WIDTH(32),
//       .NUM_INPUT(6)   // 6 inputs -> 3-bit selector (0..5 valid)
//   ) u_mux (
//       .i_data(my_array),
//       .i_sel(my_selector),
//       .o_data(result)
//   );
//
//////////////////////////////////////////////////////////////////////////////////


module simple_mux #(
    parameter int DATA_WIDTH = 16,
    parameter int NUM_INPUT  = 8,

    // Derived parameters
    parameter int NUM_INPUT_BITWIDTH = $clog2(NUM_INPUT)
)(
    input  logic [DATA_WIDTH-1:0]         i_data [NUM_INPUT],
    input  logic [NUM_INPUT_BITWIDTH-1:0] i_sel,
    output logic [DATA_WIDTH-1:0]         o_data
);

    assign o_data = i_data[i_sel];

endmodule
