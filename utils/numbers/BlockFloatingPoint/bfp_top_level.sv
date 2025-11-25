module bfp_top_level #(
    parameter int WIDTH = 16,       // Data Width (e.g., 16, 32)
    parameter int BLOCK_SIZE = 256, // Samples per block
    parameter bit IS_SIGNED = 1     // 1 = Signed (2's Comp), 0 = Unsigned
)(
    input  logic clk,
    input  logic rst_n,

    // Parameterized Inputs
    input  logic [WIDTH-1:0] i_in,
    input  logic [WIDTH-1:0] q_in,
    input  logic valid_in,
    input  logic last_in, // Signals the last sample of the block

    // Parameterized Outputs
    output logic [WIDTH-1:0] i_out,
    output logic [WIDTH-1:0] q_out,

    // Dynamic Exponent Width:
    // If WIDTH=16, max shift is 16. We need 5 bits ($clog2(17)).
    // If WIDTH=32, max shift is 32. We need 6 bits ($clog2(33)).
    output logic [$clog2(WIDTH+1)-1:0] exponent_out,
    output logic valid_out
);

    // ---------------------------------------------------------
    // Internal Signals
    // ---------------------------------------------------------

    // Magnitude is always Unsigned, even if Input is Signed
    logic [WIDTH-1:0] mag;

    // Shift Factor needs specific width calculated from WIDTH parameter
    localparam SHIFT_WIDTH = $clog2(WIDTH+1);
    logic [SHIFT_WIDTH-1:0] calculated_shift;

    // FIFO Data Signals
    logic [WIDTH-1:0] fifo_i, fifo_q;
    logic fifo_valid;

    // ---------------------------------------------------------
    // 1. Magnitude Estimation
    // ---------------------------------------------------------
    // Calculates |I| + |Q|/2 approx to find signal envelope
    complex_magnitude #(
        .WIDTH(WIDTH),
        .IS_SIGNED(IS_SIGNED)
    ) mag_inst (
        .i_in(i_in),
        .q_in(q_in),
        .mag_out(mag)
    );

    // ---------------------------------------------------------
    // 2. Block Peak & Shift Calculation
    // ---------------------------------------------------------
    // Watches the magnitude stream, finds the peak, determines Leading Zeros
    bfp_calculator #(
        .DATA_WIDTH(WIDTH),
        .BLOCK_SIZE(BLOCK_SIZE)
    ) bfp_calc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid(valid_in),
        .last_sample(last_in),
        .mag_in(mag),
        .shift_factor(calculated_shift) // Output valid 1 cycle after last_sample (assuming pipelined or fast)
    );

    // ---------------------------------------------------------
    // 3. Data FIFO (Delay Line)
    // ---------------------------------------------------------
    // Stores the raw data while the calculator analyzes the block.
    // The FIFO depth must match BLOCK_SIZE exactly for alignment.
    // Note: Width is 2*WIDTH because we store I and Q together.

    simple_fifo #(
        .DATA_WIDTH(2 * WIDTH),
        .DEPTH(BLOCK_SIZE)
    ) data_fifo (
        .clk(clk), 
        .rst_n(rst_n),
        .push(valid_in),
        .din({i_in, q_in}),      // Pack I and Q
        .pop(valid_in),          // Read out at same rate we write (constant delay)
        .dout({fifo_i, fifo_q}), // Unpack I and Q
        .valid(fifo_valid)       // Valid indicates data is emerging from delay
    );

    // ---------------------------------------------------------
    // 4. Dynamic Shifter (Normalization)
    // ---------------------------------------------------------
    // Shifts the data LEFT to remove leading zeros (maximize dynamic range).
    // This effectively boosts quiet signals to use the full bit width.

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_out <= '0;
            q_out <= '0;
            exponent_out <= '0;
            valid_out <= 1'b0;
        end else begin
            if (fifo_valid) begin
                // Apply the Block Exponent
                // Note: We assume 'calculated_shift' is stable for the duration 
                // of the block coming out of the FIFO.
                i_out <= fifo_i << calculated_shift;
                q_out <= fifo_q << calculated_shift;

                exponent_out <= calculated_shift;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule
