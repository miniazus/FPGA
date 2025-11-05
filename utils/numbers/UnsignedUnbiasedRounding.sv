//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : Unsigned Unbiased Rounding
// Description   : This module performs unbiased rounding (round-half-to-even) 
//                 for unsigned fixed-point inputs. It truncates the fractional bits 
//                 of the input, performs rounding based on the fractional part, 
//                 and saturates the output if rounding causes overflow.
//
// Parameters:
//   DATA_WIDTH_IN  : Width of the unsigned input
//   DATA_WIDTH_OUT : Width of the unsigned output
//
// Inputs:
//   clk  : Clock signal for synchronous output
//   ena  : Enable signal for updating output
//   din  : Unsigned input of DATA_WIDTH_IN bits
//
// Outputs:
//   dout : Unsigned output of DATA_WIDTH_OUT bits, rounded and saturated
//
// Features:
//   - Unbiased rounding: round-half-to-even for tie cases
//   - Saturation: prevents overflow on unsigned output
//   - Synthesizable for FPGA/ASIC
//   - Handles pass-through when output width >= input width
//////////////////////////////////////////////////////////////////////////////////

module UnsignedUnbiasedRounding #(
    parameter int DATA_WIDTH_IN  = 0,
    parameter int DATA_WIDTH_OUT = 0
)
(
    input  logic clk, ena,
    input  logic unsigned [DATA_WIDTH_IN-1 :0] din,
    output logic unsigned [DATA_WIDTH_OUT-1:0] dout
);

    localparam int                              FRACWIDTH   = DATA_WIDTH_IN-DATA_WIDTH_OUT;
    localparam unsigned [DATA_WIDTH_OUT-1:0]    MAXVAL      = {(DATA_WIDTH_OUT){1'b1}};
    localparam unsigned [FRACWIDTH-1:0]         FRAC05      = 1 << (FRACWIDTH-1);

    generate
        // Check parameter validity
        if (DATA_WIDTH_IN <= 0) begin : gen_error_DATA_WIDTH_IN
            initial begin
                $error("DATA_WIDTH_IN must be > 0");
            end
        end

        if (DATA_WIDTH_OUT <= 0) begin : gen_error_DATA_WIDTH_OUT
            initial begin
                $error("DATA_WIDTH_OUT must be > 0");
            end
        end

        if (FRACWIDTH < 0) begin : gen_error_FRACWIDTH
            initial begin
                $error("DATA_WIDTH_OUT (%0d) cannot be larger than DATA_WIDTH_IN (%0d)",
                        DATA_WIDTH_OUT, DATA_WIDTH_IN);
            end
        end


        //=======================================================
        if (FRACWIDTH > 0) begin : gen_frac
            logic unsigned [DATA_WIDTH_OUT-1:0] d_rounded;
            logic unsigned [DATA_WIDTH_OUT-1:0] temp;

            always_comb begin
                // Unbiased rounding ============================
                // Round-half-to-even
                logic round_up;

                d_rounded = din[DATA_WIDTH_IN-1:FRACWIDTH];
                temp      = d_rounded;
                round_up  = (din[FRACWIDTH-1:0] > FRAC05) ||
                            ((din[FRACWIDTH-1:0] == FRAC05) && d_rounded[0]);
                d_rounded = d_rounded + round_up;

                //Truncate ======================================
                if (d_rounded < temp)
                    d_rounded = MAXVAL;
            end

            always_ff @(posedge clk) begin
                if (ena) begin
                    dout <= d_rounded;
                end
            end
        end


        else begin : gen_pass_throught
            assign dout = din;
        end
    endgenerate

endmodule
