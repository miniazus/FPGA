//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : UnbiasedRounding with CurrentPrecision
// Date          : November 10, 2025
// Description   : Performs unbiased rounding (Convergent Rounding/Round-Half-To-Even)
//                 for fixed-point numbers with dynamic input width support.
//
//                 The module:
//                 1. Identifies the valid data based on 'i_current_precision'.
//                 2. Truncates/Rounds the input from 'i_current_precision' down to 'DATA_WIDTH_OUT'.
//                 3. Saturates the result if the rounding operation causes an overflow.
//                 4. Supports both Signed (2's complement) and Unsigned arithmetic.
//
// Parameters:
//   DATA_WIDTH_IN : The physical hardware width of the input bus 'i_data'.
//                       (Static compile-time limit).
//   DATA_WIDTH_OUT    : The fixed width of the output bus 'o_data'.
//   IS_SIGNED         : Set to 1 for signed input/output, 0 for unsigned.
//
// Inputs:
//   i_clk      : Clock signal for synchronous output.
//   i_ena      : Enable signal to update output.
//   i_current_precision : [Logic/Integer] The actual valid bit-width of the current 'i_data'.
//              Must be <= DATA_WIDTH_IN. Used to determine the position
//              of the MSB and the rounding point.
//   i_data      : Input data bus of size [DATA_WIDTH_IN-1:0].
//
// Outputs:
//   o_data     : Rounded and saturated output of [DATA_WIDTH_OUT-1:0].
//
// Features:
//   - Unbiased rounding (eliminates DC bias in statistical signal processing).
//   - Dynamic Input Width: Can process varying signal widths without reconfiguration.
//   - Saturation logic handles overflow/underflow cases.
//   - Synthesizable for FPGA/ASIC.
//
// !!! DELAY = 1
//
// Usage Example:
//   UnbiasedRounding_wCurrentPrecision #(
//       .DATA_WIDTH_IN(32),
//       .DATA_WIDTH_OUT(16),
//       .IS_SIGNED(1)
//   ) u_rounder (
//       .i_clk(i_clk),
//       .i_ena(i_ena),
//       .i_current_precision(i_current_precision),
//       .i_data(i_data),
//       .o_data(o_data)
//   );
//
//////////////////////////////////////////////////////////////////////////////////

module UnbiasedRounding_wCurrentPrecision #(
    parameter int  WIDTH_IN  = 19,
    parameter int  WIDTH_OUT = 16,
    parameter bit  IS_SIGNED = 1      // 0 = unsigned, 1 = signed
)
(
    input  logic i_clk, i_ena,
    input  logic [7:0] i_current_precision,
    input  logic [WIDTH_IN-1 :0] i_data,
    output logic [WIDTH_OUT-1:0] o_data
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


    logic [WIDTH_IN-1 :0] i_data_t;
    logic [7:0] shift_amt;

    assign shift_amt = WIDTH_IN - i_current_precision;

    generate
        if (IS_SIGNED)
            assign i_data_t = $signed(i_data)   <<< shift_amt;
        else
            assign i_data_t = $unsigned(i_data) <<  shift_amt;
    endgenerate


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
                    o_data <= i_data_t;
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
                d_trunc =i_data_t[WIDTH_IN-1:DIFFWIDTH];

                // Step 2: unbiased rounding (round-half-to-even)
                round_up  = (i_data_t[DIFFWIDTH-1:0] > FRAC05) ||
                            ((i_data_t[DIFFWIDTH-1:0] == FRAC05) && d_trunc[0]);

                // 3. Apply rounding depending on mode
                if (IS_SIGNED) begin : gen_signed_rounding
                    // Signed rounding
                    d_temp = {d_trunc[WIDTH_OUT-1], d_trunc} +
                            (i_data_t[WIDTH_IN-1] ? -round_up : round_up);
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
                        d_rounded =i_data_t[WIDTH_IN-1] ? MINVALsigned : MAXVALsigned;
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


    // (Synthesizers usually ignore 'initial' blocks for logic generation)
    initial begin
        if (i_current_precision > WIDTH_OUT)
            $error("Parameter i_current_precision must be <= WIDTH_OUT");
    end

endmodule
