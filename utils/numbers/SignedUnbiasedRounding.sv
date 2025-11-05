//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : Signed Unbiased Rounding
// Description   : This module performs unbiased rounding (round-half-to-even) 
//                 for signed fixed-point inputs. It truncates the fractional bits 
//                 of the input, performs rounding based on the fractional part, 
//                 and saturates the output if rounding causes overflow.
//
// Parameters:
//   DATA_WIDTH_IN  : Width of the signed input
//   DATA_WIDTH_OUT : Width of the signed output
//
// Inputs:
//   clk  : Clock signal for synchronous output
//   ena  : Enable signal for updating output
//   din  : Signed input of DATA_WIDTH_IN bits
//
// Outputs:
//   dout : Signed output of DATA_WIDTH_OUT bits, rounded and saturated
//
// Features:
//   - Unbiased rounding: round-half-to-even for tie cases
//   - Saturation: prevents overflow on signed output
//   - Synthesizable for FPGA/ASIC
//   - Handles pass-through when output width >= input width
//////////////////////////////////////////////////////////////////////////////////

module SignedUnbiasedRounding #(
    parameter int DATA_WIDTH_IN  = 0,
    parameter int DATA_WIDTH_OUT = 0
)
(
    input  logic clk, ena,
    input  logic signed [DATA_WIDTH_IN-1 :0] din,
    output logic signed [DATA_WIDTH_OUT-1:0] dout
);

    localparam int                              FRACWIDTH   = DATA_WIDTH_IN-DATA_WIDTH_OUT;
    localparam signed   [DATA_WIDTH_OUT-1:0]    MAXVAL      = {1'b0, {(DATA_WIDTH_OUT-1){1'b1}}};
    localparam signed   [DATA_WIDTH_OUT-1:0]    MINVAL      = {1'b1, {(DATA_WIDTH_OUT-1){1'b0}}};
    localparam logic    [FRACWIDTH-1:0]         FRAC05      = 1 << (FRACWIDTH-1);

    generate
        if (FRACWIDTH > 0) begin : gen_frac
            logic signed [DATA_WIDTH_OUT-1:0] d_rounded;

            always_comb begin
                // Unbiased rounding ============================
                // Round-half-to-even
                logic round_up;

                d_rounded = din[DATA_WIDTH_IN-1:FRACWIDTH];
                round_up  = (din[FRACWIDTH-1:0] > FRAC05) ||
                            ((din[FRACWIDTH-1:0] == FRAC05) && d_rounded[0]);
                d_rounded = d_rounded + round_up;

                //Truncate ======================================
                if (din[DATA_WIDTH_IN-1] != d_rounded[DATA_WIDTH_OUT-1])
                    d_rounded = (din[DATA_WIDTH_IN-1] == 0) ? MAXVAL : MINVAL;
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
