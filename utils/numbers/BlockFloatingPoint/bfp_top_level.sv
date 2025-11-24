module bfp_top_level (
    input logic clk,
    input logic rst_n,
    input logic signed [15:0] i_in, q_in,
    input logic valid_in,
    input logic last_in,
    
    output logic signed [15:0] i_out, q_out,
    output logic [3:0] exponent_out,
    output logic valid_out
);

    // Signals
    logic [15:0] mag;
    logic [3:0]  calculated_shift;
    logic signed [15:0] fifo_i, fifo_q;
    logic fifo_valid;

    // 1. Calculate Magnitude immediately
    complex_magnitude mag_inst (
        .i_in(i_in), .q_in(q_in), .mag_out(mag)
    );

    // 2. Find the peak and calculate shift for this block
    bfp_calculator bfp_calc_inst (
        .clk(clk), .rst_n(rst_n), 
        .i_valid(valid_in), .last_sample(last_in), 
        .mag_in(mag), 
        .shift_factor(calculated_shift)
    );

    // 3. Delay the Data (FIFO)
    // The FIFO depth must equal the Block Size so data comes out 
    // exactly when 'calculated_shift' is ready.
    simple_fifo #(.DEPTH(256)) data_fifo (
        .clk(clk), .din({i_in, q_in}), .push(valid_in),
        .dout({fifo_i, fifo_q}), .valid(fifo_valid)
        // Note: Real FIFO needs careful read/write pointer logic 
        // to align with the block boundary
    );

    // 4. Dynamic Shifter
    // Apply the shift calculated from the "Future" (the analysis of the whole block)
    always_ff @(posedge clk) begin
        if (fifo_valid) begin
            // Left shift to maximize dynamic range (normalize)
            // Or right shift if your logic was designed to prevent overflow from a larger accumulator
            i_out <= fifo_i << calculated_shift; 
            q_out <= fifo_q << calculated_shift;
            
            // Output the exponent so the next stage knows how much we scaled
            exponent_out <= calculated_shift; 
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule