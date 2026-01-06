//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : UnbiasedRounding
// Date          : November 10, 2025
// Description   : Performs unbiased rounding (round-half-to-even) for fixed-point
//                 numbers. The module truncates the lower bits of the input, applies
//                 rounding based on the truncated portion, and saturates the output
//                 if rounding causes overflow. Supports both signed and unsigned
//                 inputs, and handles fractional or integer rounding modes.
//
// Parameters:
//   DATA_WIDTH_IN  : Width of the input number
//   DATA_WIDTH_OUT : Width of the output number
//   IS_SIGNED      : Set to 1 for signed input/output, 0 for unsigned
//
// Inputs:
//   i_clk  : Clock signal for synchronous output
//   i_ena  : Enable signal to update output
//   i_data  : Input number of DATA_WIDTH_IN bits
//
// Outputs:
//   o_data : Rounded and saturated output of DATA_WIDTH_OUT bits
//
// Features:
//   - Unbiased rounding (round-half-to-even) for tie cases
//   - Saturation to prevent overflow on output
//   - Synthesizable for FPGA/ASIC
//   - Pass-through mode when output width equals input width
//
// !!! DELAY = 1
//
// Using:
// UnbiasedRounding #(.WIDTH_IN(...),.WIDTH_OUT(...),.IS_SIGNED(...))
//                 (.i_clk(...),.i_ena(...),.i_data(...),.o_data(...));
//
//////////////////////////////////////////////////////////////////////////////////

module UnbiasedRounding #(
    parameter int  WIDTH_IN     = 19,
    parameter int  WIDTH_OUT    = 16,
    parameter bit  IS_SIGNED    = 1      // 0 = unsigned, 1 = signed
)
(
    input  logic i_clk, i_ena,
    input  logic signed [WIDTH_IN-1 :0] i_data,
    output logic signed [WIDTH_OUT-1:0] o_data
);
    // Difference in width between input and output
    localparam int                         DIFFWIDTH   = WIDTH_IN-WIDTH_OUT;
    // Maximum and minimum output values for saturation
    localparam signed   [WIDTH_OUT-1:0]    MAXVALunsigned = {(WIDTH_OUT){1'b1}};
    localparam signed   [WIDTH_OUT-1:0]    MAXVALsigned   = {1'b0, {(WIDTH_OUT-1){1'b1}}};
    localparam signed   [WIDTH_OUT-1:0]    MINVALsigned   = {1'b1, {(WIDTH_OUT-1){1'b0}}};
    // Halfway value used for round-half-to-even
    localparam unsigned [DIFFWIDTH > 0 ? DIFFWIDTH-1 : 0] FRAC05 = (DIFFWIDTH > 0) ?
                                                                        (1 << (DIFFWIDTH-1)) : 0;

    generate
        // Check parameter validity
        if (WIDTH_IN <= 0) begin : gen_error_WIDTH_IN
            initial begin
                $error("DATA_WIDTH_IN must be > 0");
            end
        end

        if (WIDTH_OUT <= 0) begin : gen_error_WIDTH_OUT
            initial begin
                $error("DATA_WIDTH_OUT must be > 0");
            end
        end

        if (DIFFWIDTH < 0) begin : gen_error_DIFFWIDTH
            initial begin
                $error("WIDTH_OUT (%0d) cannot be larger than WIDTH_IN (%0d)",
                        WIDTH_OUT, WIDTH_IN);
            end
        end


        //=======================================================
        // If no bit difference, just pass through
        if (DIFFWIDTH == 0) begin : gen_pass_throught
            always_ff @(posedge i_clk) begin
                if (i_ena) begin
                    o_data <= i_data;
                end
            end
        end
        else begin : gen_rounding
            logic signed [WIDTH_OUT-1:0]   d_rounded;
            logic signed [WIDTH_OUT-1:0]   d_trunc;
            logic                          round_up;
            logic signed [WIDTH_OUT:0]     d_temp; // one extra bit for rounding carry

            always_comb begin
                // Step 1: truncate to target width
                d_trunc = i_data[WIDTH_IN-1:DIFFWIDTH];

                // Step 2: unbiased rounding (round-half-to-even)
                round_up  = (i_data[DIFFWIDTH-1:0] > FRAC05) ||
                            ((i_data[DIFFWIDTH-1:0] == FRAC05) && d_trunc[0]);

                // 3. Apply rounding depending on mode
                if (IS_SIGNED) begin : gen_signed_rounding
                    // Signed rounding
                    d_temp = {d_trunc[WIDTH_OUT-1], d_trunc} +
                            (i_data[WIDTH_IN-1] ? -round_up : round_up);
                end
                else begin : gen_unsigned_rounding
                    // Unsigned rounding
                    d_temp = {1'b0, d_trunc} + round_up;
                end


                // Step 4: saturation check
                if (IS_SIGNED) begin : gen_signed_saturation
                    // Signed saturation
                    if (d_temp[WIDTH_OUT] != d_temp[WIDTH_OUT-1]) begin
                        // overflow happened
                        d_rounded = i_data[WIDTH_IN-1] ? MINVALsigned : MAXVALsigned;
                    end else begin
                        // no overflow
                        d_rounded = d_temp[WIDTH_OUT-1:0];
                    end
                end
                else begin : gen_unsigned_saturation
                    // Unsigned saturation
                    if (d_temp[WIDTH_OUT])
                        d_rounded = MAXVALunsigned;
                    else
                        d_rounded = d_temp[WIDTH_OUT-1:0];
                end
            end


            always_ff @(posedge i_clk) begin
                if (i_ena) begin
                    o_data <= d_rounded;
                end
            end
        end
    endgenerate

endmodule
