//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : Multi Input Adder
// Description   : This module performs signed addition of multiple input values.
//                 The number of inputs is parameterizable. The output width is 
//                 automatically extended by $clog2(NUM_INPUT) bits to prevent 
//                 overflow. Designed for use in arithmetic datapaths or DSP 
//                 pipelines where accumulation of several fixed-point signals 
//                 is required.
// Parameters:
//   NUM_INPUT      : Number of inputs
//   DATA_WIDTH_IN  : Width of the signed input
//
// Inputs:
//   clk  : Clock signal (used if registered output is desired)
//   ena  : Enable signal for registered output
//   din  : Signed input of DATA_WIDTH_IN bits
//
// Outputs:
//   dout : Signed output of DATA_WIDTH_IN+$clog2(N) bits
//
// Features:
//   - Parameterizable number of inputs (NUM_INPUT)
//   - Supports signed addition of all inputs
//   - Output width automatically scales with $clog2(NUM_INPUT)
//   - Synthesizable and FPGA/ASIC friendly
//   - Simple, single-cycle combinational implementation
//   - Easily extendable for pipelined or tree-based summation
//////////////////////////////////////////////////////////////////////////////////

module MultiInputAdder #(
    parameter int NUM_INPUT = 2,
    parameter int WIDTH_IN  = 0
)
(
    input  logic clk, ena,
    input  logic signed [WIDTH_IN-1 :0]                    din [NUM_INPUT],
    output logic signed [WIDTH_IN+$clog2(NUM_INPUT)-1:0]   dout
);

    generate
        // Check parameter validity
        if (WIDTH_IN <= 0) begin : gen_error_DATA_WIDTH_IN
            initial begin
                $error("DATA_WIDTH_IN must be > 0");
            end
        end


        //========================================
        else begin : gen_Adder
            logic signed [WIDTH_IN+$clog2(NUM_INPUT)-1:0] sum;

            always_comb begin
                sum = '0;
                for (int i = 0; i < NUM_INPUT; i++) begin
                    sum += din[i];
                end
            end

            always_ff @(posedge clk) begin
                if (ena)
                    dout <= sum;
            end
        end
    endgenerate

endmodule
