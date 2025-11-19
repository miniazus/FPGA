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
//
// Using:
// MultiInputAdder #(.NUM_INPUT(...),.WIDTH_IN(...))
//                 (.clk(...),.ena(...),.din(...),.dout(...));
//
//////////////////////////////////////////////////////////////////////////////////

module MultiInputAdder #(
    parameter int NUM_INPUT = 2,
    parameter int WIDTH_IN  = 0,
    parameter bit IS_SIGNED = 1,
    parameter bit TRUNCATE  = 1,

    // derived parameters
    parameter int WIDTH_SUM = WIDTH_IN + $clog2(NUM_INPUT),
    parameter int WIDTH_OUT = TRUNCATE ? WIDTH_IN : WIDTH_SUM
)
(
    input  logic clk, ena,
    input  logic [WIDTH_IN -1:0] din [NUM_INPUT],
    output logic [WIDTH_OUT-1:0] dout
);

    // Balanced adder tree
    function automatic logic [WIDTH_SUM-1:0]
        adder_tree (input logic [WIDTH_IN-1:0] f_din [NUM_INPUT], input logic f_signed);

        // Declare everything first
        logic [WIDTH_SUM-1:0] f_results [$clog2(NUM_INPUT)+1][NUM_INPUT];
        int i, ii;
        int f_num_item, f_stage;
        int f_num_add, f_from, f_to;


        // Stage 0: sign/zero extend ----
        for (i=0; i<NUM_INPUT; i++) begin
            if (!f_signed)
                f_results[0][i] = {{(WIDTH_SUM-WIDTH_IN){1'b0}} , f_din[i]};
            else
                f_results[0][i] = {{(WIDTH_SUM-WIDTH_IN){f_din[i][WIDTH_IN-1]}} , f_din[i]};
        end

        // Consequent stages:  Build the tree ----
        f_num_item = NUM_INPUT;
        f_stage = 0;
        //
        while (f_num_item > 1) begin
            f_stage++;
            f_num_add  = (f_num_item + 1) >> 1;
            //
            for (ii=0; ii<f_num_add; ii++) begin
                f_from = ii*2;
                f_to   = f_from + 1;

                if (f_to >= f_num_item)
                    f_results[f_stage][ii] = f_results[f_stage-1][f_from];
                else
                    f_results[f_stage][ii] = f_results[f_stage-1][f_from] +
                                             f_results[f_stage-1][f_to];
            end

            f_num_item = f_num_add;
        end

        return f_results[f_stage][0];
    endfunction


    generate
        // Check parameter validity
        if (WIDTH_IN <= 0) begin : gen_error_DATA_WIDTH_IN
            initial begin
                $error("DATA_WIDTH_IN must be > 0");
            end
        end

        //========================================
        else begin : gen_Adder
            logic [WIDTH_SUM-1:0] t_sum;

            always_comb
                t_sum = adder_tree(.f_din(din), .f_signed(IS_SIGNED));

            if (TRUNCATE) begin : gen_Truncate
                UnbiasedRounding #(.WIDTH_IN (WIDTH_SUM),
                                   .WIDTH_OUT(WIDTH_OUT),
                                   .IS_SIGNED(IS_SIGNED))
                       u_rounding (.clk (clk),
                                   .ena (ena),
                                   .din (t_sum),
                                   .dout(dout));
            end
            else begin : gen_Without_Truncate
                always_ff @(posedge clk) begin
                    if (ena)
                        dout <= t_sum;
                end
            end
        end
    endgenerate

endmodule
