module CalcBitGrowth #(
    parameter int NUM_INPUT = 8,
    parameter int ORI_WIDTH = 16
)(
    input  logic [NUM_INPUT-1:0] ctr_in,
    output logic [7:0]           width
);

    logic [$clog2(NUM_INPUT+1)-1:0] counted_ones;
    logic [$clog2(NUM_INPUT+1)-1:0] num_add_bit;

    always_comb begin
        // Step A: Hardware Bit Counter
        counted_ones = $countones(ctr_in);

        // Step B: Loop to find Log2 (Priority Encoder)
        num_add_bit = 0; // Default value

        for (int i = 0; i < $clog2(NUM_INPUT); i++) begin
            if (counted_ones > (1 << i)) begin
                num_add_bit = i + 1;
            end
        end

        // Step C: Add to base width
        width = num_add_bit + ORI_WIDTH;
    end

endmodule
