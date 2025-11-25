module bfp_calculator #(
    parameter int WIDTH = 16
)(
    input  logic clk,
    input  logic rst_n,
    input  logic i_valid,
    input  logic last_sample,
    input  logic [WIDTH-1:0] mag_in,

    output logic [$clog2(WIDTH+1)-1:0] shift_factor,
    output logic shift_valid // Tells the next stage "Calculation Done"
);

    logic [WIDTH-1:0] block_peak;
    logic [WIDTH-1:0] latched_final_peak;
    logic calc_enable;

    // ---------------------------------------------------------
    // STAGE 1: Peak Detection & Latching
    // ---------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            block_peak <= '0;
            latched_final_peak <= '0;
            calc_enable <= 1'b0;
        end else if (i_valid) begin
            // 1. Peak Tracking
            if (last_sample) begin
                // On the last sample, we finalize the peak calculation
                // comparing the accumulated peak vs the current incoming sample
                latched_final_peak <= (mag_in > block_peak) ? mag_in : block_peak;

                block_peak <= '0; // Reset for next block
                calc_enable <= 1'b1; // Trigger Stage 2
            end
            else begin
                // Normal accumulation
                if (mag_in > block_peak)
                    block_peak <= mag_in;

                calc_enable <= 1'b0;
            end
        end else begin
            calc_enable <= 1'b0;
        end
    end

    // ---------------------------------------------------------
    // STAGE 2: Leading Zero Calculation (Dedicated Cycle)
    // ---------------------------------------------------------
    // Now 'latched_final_peak' is a stable register.
    // This entire clock cycle is dedicated JUST to the loop.

    logic [$clog2(WIDTH+1)-1:0] calc_zeros;

    always_comb begin
        calc_zeros = WIDTH; // Default
        for (int i = WIDTH-1; i >= 0; i--) begin
            if (latched_final_peak[i] == 1'b1) begin
                calc_zeros = WIDTH - 1 - i;
                break;
            end
        end
    end

    // Output Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_factor <= '0;
            shift_valid <= 1'b0;
        end else begin
            shift_valid <= calc_enable; // Pulse valid 1 cycle after last_sample
            if (calc_enable) begin
                shift_factor <= calc_zeros;
            end
        end
    end

endmodule
