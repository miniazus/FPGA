//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : simple_demux
// Date          : January 5, 2026
// Description   : A fully parameterized 1-to-N Demultiplexer.
//
//                 Key capabilities:
//                 1. Routing: Routes a single input data stream to one of N 
//                    output channels based on the selection index.
//                 2. Validation: Generates a 'Valid' flag for the active channel,
//                    allowing downstream logic to know which output is active.
//                 3. Safety: Inactive channels are zeroed out to prevent data
//                    leakage or accidental processing of stale data.
//
// Parameters:
//   DATA_WIDTH : Bit width of the input/output signals.
//   NUM_INPUT  : Number of output channels.
//
// Inputs:
//   i_data : Input data to be routed.
//   i_sel  : Selection index. Width is automatically calculated.
//
// Outputs:
//   o_data  : Unpacked array of output channels [NUM_INPUT] x [DATA_WIDTH].
//   o_valid : Unpacked array of valid flags [NUM_INPUT] (1 bit per channel).
//
// !!! DELAY = 0 (Purely Combinational)
//
// Usage Example:
//   simple_demux #(
//       .DATA_WIDTH(16),
//       .NUM_INPUT(4)
//   ) u_demux (
//       .i_data(incoming_stream),
//       .i_sel(channel_select),
//       .o_data(demux_outputs), // Array of 4
//       .o_valid(demux_valids)  // Array of 4
//   );
//
//////////////////////////////////////////////////////////////////////////////////


module simple_demux #(
    parameter int DATA_WIDTH = 16,
    parameter int NUM_INPUT  = 8,

    // Derived parameters
    parameter int NUM_INPUT_BITWIDTH = $clog2(NUM_INPUT)
)(
    input  logic [DATA_WIDTH-1:0]         i_data,
    input  logic [NUM_INPUT_BITWIDTH-1:0] i_sel,
    output logic [DATA_WIDTH-1:0]         o_data  [NUM_INPUT],
    output logic                          o_valid [NUM_INPUT]
);

    always_comb begin
        for (int i=0; i<NUM_INPUT; i++) begin
            if (i==i_sel) begin
                o_data [i] = i_data;
                o_valid[i] = 1'b1;
            end
            else begin
                o_data[i]  = '0;
                o_valid[i] = 1'b0;
            end
        end
    end

endmodule
