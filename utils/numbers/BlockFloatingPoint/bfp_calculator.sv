module bfp_calculator #(
    parameter int DATA_WIDTH = 16,
    parameter int BLOCK_SIZE = 256
)(
    input  logic clk,
    input  logic rst_n,
    input  logic i_valid,
    input  logic last_sample, // High on the last sample of the block
    input  logic [DATA_WIDTH-1:0] mag_in,
    //
    output logic [3:0] shift_factor // How many bits to shift
);

    logic [DATA_WIDTH-1:0] block_peak;
    logic [DATA_WIDTH-1:0] current_max;
    logic [3:0]            leading_zeros;

    // 1. Peak Detector Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            block_peak <= '0;
        end else if (i_valid) begin
            if (last_sample) begin
                // End of block: Reset peak for next block
                block_peak <= '0;
            end else begin
                // Track the maximum value seen so far
                if (mag_in > block_peak) block_peak <= mag_in;
            end
        end
    end

    // 2. Count Leading Zeros (CLZ) - Combinational
    // This determines how much "headroom" we have.
    // Simple Priority Encoder logic for 16-bit data:
    always_comb begin
        // Check the peak captured at the very end of the logic
        logic [DATA_WIDTH-1:0] final_peak;
        final_peak = (mag_in > block_peak) ? mag_in : block_peak;

        if (final_peak[15])      leading_zeros = 0;
        else if (final_peak[14]) leading_zeros = 1;
        else if (final_peak[13]) leading_zeros = 2;
        else if (final_peak[12]) leading_zeros = 3;
        else if (final_peak[11]) leading_zeros = 4;
        else if (final_peak[10]) leading_zeros = 5;
        else if (final_peak[9])  leading_zeros = 6;
        // ... and so on ...
        else                     leading_zeros = 15; // Signal is effectively zero
    end

    // 3. Output Latch
    // Update the shift factor only at the end of the block
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) shift_factor <= 0;
        else if (last_sample && i_valid) begin
            shift_factor <= leading_zeros;
        end
    end

endmodule