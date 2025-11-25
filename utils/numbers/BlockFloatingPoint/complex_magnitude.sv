// $$|Mag| = \sqrt{I^2 + Q^2}$$
// Calculating a square root in hardware requires iterative algorithms (like CORDIC),
// which are slow and expensive. We need a linear approximation.
// The "Alpha Max + Beta Min" Theory:
// $$|Mag| \approx \alpha \cdot \text{Max}(|I|,|Q|) + \beta \cdot \text{Min}(|I|,|Q|)$$
// $\alpha = 1$:   multiplying by 1 is just a wire.
// $\beta  = 0.5$: multiplying by $0.5$ is just a Right Shift by 1 bit (>> 1).

module complex_magnitude #(
    parameter int WIDTH = 16,
    parameter bit IS_SIGNED = 1         // 0 = Unsigned Input, 1 = Signed Input
)(
    input  logic [WIDTH-1:0] i_in,      // Generic bits (type determined by param)
    input  logic [WIDTH-1:0] q_in,
    output logic [WIDTH-1:0] mag_out
);

    // 1. Unified Absolute Value Logic
    // -------------------------------
    logic [WIDTH-1:0] abs_i, abs_q;

    always_comb begin
        if (IS_SIGNED) begin
            // CASE: SIGNED INPUTS
            // Check MSB or use $signed() to determine if negative.
            // Note: We cast to signed for the check, but the result is stored as unsigned bits.
            // Handling -Max (e.g., -32768) -> +32768 works because the bit pattern
            // 1000... is -Max in signed but +Max+1 in unsigned.
            abs_i = ($signed(i_in) < 0) ? -($signed(i_in)) : $signed(i_in);
            abs_q = ($signed(q_in) < 0) ? -($signed(q_in)) : $signed(q_in);

            abs_i = i_in[WIDTH-1] ? ~i_in+1 : i_in;

        end else begin
            // CASE: UNSIGNED INPUTS
            // Pass through directly
            abs_i = i_in;
            abs_q = q_in;
        end
    end

    // 2. Max / Min Sorting (Always Unsigned from here on)
    // ---------------------------------------------------
    logic [WIDTH-1:0] max_val, min_val;

    always_comb begin
        if (abs_i > abs_q) begin
            max_val = abs_i;
            min_val = abs_q;
        end else begin
            max_val = abs_q;
            min_val = abs_i;
        end
    end

    // 3. Alpha Max + Beta Min Calculation
    // -----------------------------------
    // We use one extra bit for the sum to detect overflow safely
    logic [WIDTH:0] sum_temp;

    // Formula: Max + (Min / 2) (Here, \alpha = 1, \beta  = 0.5)
    assign sum_temp = max_val + (min_val >> 1);

    // 4. Final Saturation
    // -------------------
    // If input was Unsigned 255, result could be 382. We must clip to 255.
    assign mag_out = (sum_temp > {WIDTH{1'b1}}) ? {WIDTH{1'b1}} : sum_temp[WIDTH-1:0];

endmodule
