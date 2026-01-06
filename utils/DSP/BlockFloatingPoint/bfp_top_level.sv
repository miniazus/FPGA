module bfp_top_level #(
    parameter int WIDTH = 16,       // Data Width (e.g., 16, 32)
    parameter int BLOCK_SIZE = 256, // Samples per block
    parameter bit IS_SIGNED = 1     // 1 = Signed (2's Comp), 0 = Unsigned
)(
    input  logic i_clk,
    input  logic i_rst_n,

    // Parameterized Inputs
    input  logic [WIDTH-1:0] i_I,
    input  logic [WIDTH-1:0] i_Q,
    input  logic i_valid,
    input  logic i_last, // Signals the last sample of the block

    // Parameterized Outputs
    output logic [WIDTH-1:0] o_I,
    output logic [WIDTH-1:0] o_Q,

    // Dynamic Exponent Width:
    // If WIDTH=16, max shift is 16. We need 5 bits ($clog2(17)).
    // If WIDTH=32, max shift is 32. We need 6 bits ($clog2(33)).
    output logic [$clog2(WIDTH+1)-1:0] o_exponent,
    output logic o_valid
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
        .i_I(i_I),
        .i_Q(i_Q),
        .o_mag(mag)
    );

    // ---------------------------------------------------------
    // 2. Block Peak & Shift Calculation
    // ---------------------------------------------------------
    // Watches the magnitude stream, finds the peak, determines Leading Zeros
    bfp_calculator #(
        .DATA_WIDTH(WIDTH),
        .BLOCK_SIZE(BLOCK_SIZE)
    ) bfp_calc_inst (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_valid(i_valid),
        .i_last_sample(i_last),
        .o_mag(mag),
        .o_shift_factor(calculated_shift) // Output valid 1 cycle after last_sample (assuming pipelined or fast)
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
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .push(i_valid),
        .din({i_I, i_Q}),      // Pack I and Q
        .pop(i_valid),          // Read out at same rate we write (constant delay)
        .dout({fifo_i, fifo_q}), // Unpack I and Q
        .valid(fifo_valid)       // Valid indicates data is emerging from delay
    );

    // ---------------------------------------------------------
    // 4. Dynamic Shifter (Normalization)
    // ---------------------------------------------------------
    // Shifts the data LEFT to remove leading zeros (maximize dynamic range).
    // This effectively boosts quiet signals to use the full bit width.

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_I <= '0;
            o_Q <= '0;
            o_exponent <= '0;
            o_valid <= 1'b0;
        end else begin
            if (fifo_valid) begin
                // Apply the Block Exponent
                // Note: We assume 'calculated_shift' is stable for the duration 
                // of the block coming out of the FIFO.
                o_I <= fifo_i << calculated_shift;
                o_Q <= fifo_q << calculated_shift;

                o_exponent <= calculated_shift;
                o_valid <= 1'b1;
            end else begin
                o_valid <= 1'b0;
            end
        end
    end

endmodule
