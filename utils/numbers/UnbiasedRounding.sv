//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : UnbiasedRounding
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
//   IS_FRACTION    : Set to 1 if input represents a fractional number, 0 for integer
//
// Inputs:
//   clk  : Clock signal for synchronous output
//   ena  : Enable signal to update output
//   din  : Input number of DATA_WIDTH_IN bits
//
// Outputs:
//   dout : Rounded and saturated output of DATA_WIDTH_OUT bits
//
// Features:
//   - Unbiased rounding (round-half-to-even) for tie cases
//   - Saturation to prevent overflow on output
//   - Synthesizable for FPGA/ASIC
//   - Pass-through mode when output width equals input width
//////////////////////////////////////////////////////////////////////////////////

module UnbiasedRounding #(
    parameter int  WIDTH_IN     = 0,
    parameter int  WIDTH_OUT    = 0,
    parameter bit  IS_SIGNED    = 1,      // 0 = unsigned, 1 = signed
    parameter bit  IS_FRACTION  = 0       // 0 = integer, 1 = fractional
)
(
    input  logic clk, ena,
    input  logic signed [WIDTH_IN-1 :0] din,
    output logic signed [WIDTH_OUT-1:0] dout
);
    // Difference in width between input and output
    localparam int                         DIFFWIDTH   = WIDTH_IN-WIDTH_OUT;
    // Maximum and minimum output values for saturation
    localparam signed   [WIDTH_OUT-1:0]    MAXVAL      = {1'b0, {(WIDTH_OUT-1){1'b1}}};
    localparam signed   [WIDTH_OUT-1:0]    MINVAL      = {1'b1, {(WIDTH_OUT-1){1'b0}}};
    // Halfway value used for round-half-to-even
    localparam unsigned [DIFFWIDTH-1:0]    FRAC05      = 1 << (DIFFWIDTH-1);

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
            always_ff @(posedge clk) begin
                if (ena) begin
                    dout <= din;
                end
            end
        end
        else begin : gen_rounding
            logic signed [WIDTH_OUT-1:0]   d_rounded;
            logic signed [WIDTH_OUT-1:0]   d_trunc;
            logic                               round_up;
            logic signed [WIDTH_OUT:0]     d_temp; // one extra bit for rounding carry

            always_comb begin
                // Step 1: truncate to target width
                d_trunc = din[WIDTH_IN-1:DIFFWIDTH];

                // Step 2: unbiased rounding (round-half-to-even)
                round_up  = (din[DIFFWIDTH-1:0] > FRAC05) ||
                            ((din[DIFFWIDTH-1:0] == FRAC05) && d_trunc[0]);

                // 3. Apply rounding depending on mode
                if (IS_SIGNED) begin : gen_signed_rounding
                    // Signed rounding
                    if (IS_FRACTION == 0)
                        // Integer mode: sign-based rounding
                        d_temp = {d_trunc[WIDTH_OUT-1], d_trunc} +
                                (din[WIDTH_IN-1] ? -round_up : round_up);
                    else
                        // Fractional mode: unbiased symmetric rounding (same for +-)
                        d_temp = {d_trunc[WIDTH_OUT-1], d_trunc} + round_up;
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
                        d_rounded = d_temp[WIDTH_OUT-1] ? MINVAL : MAXVAL;
                    end else begin
                        // no overflow
                        d_rounded = d_temp[WIDTH_OUT-1:0];
                    end
                end : gen_unsigned_saturation
                else begin
                    // Unsigned saturation
                    if (d_temp[WIDTH_OUT])
                        d_rounded = MAXVAL;
                    else
                        d_rounded = d_temp[WIDTH_OUT-1:0];
                end
            end


            always_ff @(posedge clk) begin
                if (ena) begin
                    dout <= d_rounded;
                end
            end
        end
    endgenerate

endmodule
