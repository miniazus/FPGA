//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : UnbiasedRounding with CurrentPrecision
// Date          : November 10, 2025
// Description   : Performs unbiased rounding (Convergent Rounding/Round-Half-To-Even)
//                 for fixed-point numbers with dynamic input width support.
//
//                 The module:
//                 1. Identifies the valid data based on 'current_precision'.
//                 2. Truncates/Rounds the input from 'current_precision' down to 'DATA_WIDTH_OUT'.
//                 3. Saturates the result if the rounding operation causes an overflow.
//                 4. Supports both Signed (2's complement) and Unsigned arithmetic.
//
// Parameters:
//   DATA_WIDTH_IN_MAX : The physical hardware width of the input bus 'din'.
//                       (Static compile-time limit).
//   DATA_WIDTH_OUT    : The fixed width of the output bus 'dout'.
//   IS_SIGNED         : Set to 1 for signed input/output, 0 for unsigned.
//
// Inputs:
//   clk      : Clock signal for synchronous output.
//   ena      : Enable signal to update output.
//   current_precision : [Logic/Integer] The actual valid bit-width of the current 'din'.
//              Must be <= DATA_WIDTH_IN_MAX. Used to determine the position
//              of the MSB and the rounding point.
//   din      : Input data bus of size [DATA_WIDTH_IN_MAX-1:0].
//
// Outputs:
//   dout     : Rounded and saturated output of [DATA_WIDTH_OUT-1:0].
//
// Features:
//   - Unbiased rounding (eliminates DC bias in statistical signal processing).
//   - Dynamic Input Width: Can process varying signal widths without reconfiguration.
//   - Saturation logic handles overflow/underflow cases.
//   - Synthesizable for FPGA/ASIC.
//
// Usage Example:
//   UnbiasedRounding_wCurrentPrecision #(
//       .DATA_WIDTH_IN_MAX(32),
//       .DATA_WIDTH_OUT(16),
//       .IS_SIGNED(1)
//   ) u_rounder (
//       .clk(sys_clk),
//       .ena(data_valid),
//       .current_precision(current_bit_depth),
//       .din(raw_data),
//       .dout(rounded_data)
//   );
//
//////////////////////////////////////////////////////////////////////////////////

module UnbiasedRounding_wCurrentPrecision #(
    parameter int  WIDTH_IN_MAX = 19,
    parameter int  WIDTH_OUT    = 16,
    parameter bit  IS_SIGNED    = 1      // 0 = unsigned, 1 = signed
)
(
    input  logic clk, ena,
    input  logic [7:0] current_precision,
    input  logic [current_precision_MAX-1 :0] din,
    output logic [WIDTH_OUT-1:0]     dout
);
    // Difference in width between input and output
    localparam int                         DIFFWIDTH   = WIDTH_IN_MAX-WIDTH_OUT;
    // Maximum and minimum output values for saturation
    localparam signed   [WIDTH_OUT-1:0]    MAXVALunsigned = {(WIDTH_OUT){1'b1}};
    localparam signed   [WIDTH_OUT-1:0]    MAXVALsigned   = {1'b0, {(WIDTH_OUT-1){1'b1}}};
    localparam signed   [WIDTH_OUT-1:0]    MINVALsigned   = {1'b1, {(WIDTH_OUT-1){1'b0}}};
    // Halfway value used for round-half-to-even
    localparam unsigned [DIFFWIDTH-1:0]    FRAC05         = 1 << (DIFFWIDTH-1);


    logic [WIDTH_IN_MAX-1 :0] din_t;

    generate
        if (IS_SIGNED)
            assign din_t = $signed(din)   <<< (WIDTH_IN_MAX - current_precision);
        else
            assign din_t = $unsigned(din) <<  (WIDTH_IN_MAX - current_precision);
    endgenerate


    generate
        // Check parameter validity
        if (WIDTH_IN_MAX <= 0) begin : gen_error_WIDTH_IN_MAX
            initial begin
                $error("DATA_WIDTH_IN_MAX must be > 0");
            end
        end

        if (WIDTH_OUT <= 0) begin : gen_error_WIDTH_OUT
            initial begin
                $error("DATA_WIDTH_OUT must be > 0");
            end
        end

        if (DIFFWIDTH < 0) begin : gen_error_DIFFWIDTH
            initial begin
                $error("WIDTH_OUT (%0d) cannot be larger than WIDTH_IN_MAX (%0d)",
                        WIDTH_OUT, WIDTH_IN_MAX);
            end
        end


        //=======================================================
        // If no bit difference, just pass through
        if (DIFFWIDTH == 0) begin : gen_pass_throught
            always_ff @(posedge clk) begin
                if (ena) begin
                    dout <=din_t;
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
                d_trunc =din_t[WIDTH_IN_MAX-1:DIFFWIDTH];

                // Step 2: unbiased rounding (round-half-to-even)
                round_up  = (din_t[DIFFWIDTH-1:0] > FRAC05) ||
                            ((din_t[DIFFWIDTH-1:0] == FRAC05) && d_trunc[0]);

                // 3. Apply rounding depending on mode
                if (IS_SIGNED) begin : gen_signed_rounding
                    // Signed rounding
                    d_temp = {d_trunc[WIDTH_OUT-1], d_trunc} +
                            (din_t[WIDTH_IN_MAX-1] ? -round_up : round_up);
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
                        d_rounded =din_t[WIDTH_IN_MAX-1] ? MINVALsigned : MAXVALsigned;
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


            always_ff @(posedge clk) begin
                if (ena) begin
                    dout <= d_rounded;
                end
            end
        end
    endgenerate


    // (Synthesizers usually ignore 'initial' blocks for logic generation)
    initial begin
        if (width_in > WIDTH_OUT)
            $error("Parameter width_in must be <= WIDTH_OUT");
    end

endmodule
