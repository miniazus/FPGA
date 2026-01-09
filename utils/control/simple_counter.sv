//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : simple_counter
// Date          : January 5, 2026
// Description   : A configurable Up/Down Counter with custom bounds.
//
//                 Key capabilities:
//                 1. Configurable Range: Counts from 0 to NUM_MAX (inclusive).
//                 2. Direction Control: Static configuration for Up or Down via
//                    parameter (efficient hardware generation).
//                 3. Safety: Includes parameter validation to prevent invalid
//                    initialization values.
//
// Parameters:
//   NUM_MAX    : The maximum count value (Wrap point).
//   UP_DOWN    : 1 = Count Up (0 -> MAX -> 0).
//                0 = Count Down (MAX -> 0 -> MAX).
//   NUM_INIT   : Initial value after reset.
//
// Inputs:
//   i_clk      : System Clock.
//   i_ena      : Clock Enable (Active High).
//   i_rst_n    : Synchronous Reset (Active Low).
//
// Outputs:
//   o_data     : Current count value.
//
// !!! DELAY = 1 (Sequential Logic)
//
// Usage Example:
// simple_counter #(
//     .NUM_MAX(10),       // Configure to count 0 to 10
//     .UP_DOWN(1)         // Configure to count UP
// ) u_counter (
//     // Format: .PortName( YourSignal )
//     .i_clk   ( sys_clk   ),  // Connect system clock
//     .i_ena   ( 1'b1      ),  // Hardwire Enable to "Always On"
//     .i_rst_n ( sys_rst_n ),  // Connect system reset
//     .o_data  ( count_val )   // Output goes to 'count_val' wire
// );
//////////////////////////////////////////////////////////////////////////////////

module simple_counter #(
    parameter int NUM_MAX  = 16,
    parameter bit UP_DOWN  = 1,  // 1: Up, 0: Down

    // Fixed: Width must hold the value "NUM_MAX" (e.g. 16 requires 5 bits)
    parameter int DATA_WIDTH = $clog2(NUM_MAX + 1),

    parameter logic [DATA_WIDTH-1:0] NUM_INIT = 0
)(
    input  logic i_clk, i_ena, i_rst_n,
    output logic [DATA_WIDTH-1:0] o_data
);

    // -------------------------------------------------------------
    // Parameter Validation (Simulation Only)
    // -------------------------------------------------------------
    initial begin
        if (NUM_INIT > NUM_MAX)
            $error("Error: NUM_INIT (%0d) must be <= NUM_MAX (%0d)", NUM_INIT, NUM_MAX);
    end

    // -------------------------------------------------------------
    // Counter Logic
    // -------------------------------------------------------------
    generate
        if (UP_DOWN) begin : gen_up_counter
            always_ff @ (posedge i_clk) begin
                if (!i_rst_n) begin
                    o_data <= NUM_INIT;
                end
                else if (i_ena) begin
                    // Count Up Logic
                    if (o_data == NUM_MAX[DATA_WIDTH-1:0]) begin
                        o_data <= '0;
                    end
                    else begin
                        o_data <= o_data + 1;
                    end
                end
            end
        end
        else begin : gen_down_counter
            always_ff @ (posedge i_clk) begin
                if (!i_rst_n) begin
                    o_data <= NUM_INIT;
                end
                else if (i_ena) begin
                    // Count Down Logic
                    if (o_data == 0) begin
                        o_data <= NUM_MAX[DATA_WIDTH-1:0];
                    end
                    else begin
                        o_data <= o_data - 1;
                    end
                end
            end
        end
    endgenerate

endmodule
