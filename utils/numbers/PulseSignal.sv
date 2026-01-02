//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : PulseSignal
// Date          : December 15, 2025
// Description   : A One-Shot Pulse Generator / Startup Sequencer.
//
//                 This module waits for a specified number of clock cycles ('DELAY')
//                 after reset is released, then asserts the output 'dout'.
//                 It is commonly used to sequence the startup of multiple modules
//                 (e.g., turn on Block A, wait 10 cycles, turn on Block B).
//
//                 Behavior:
//                 1. Starts counting immediately when 'rst_n' is released.
//                 2. If 'ena' is low, the counter pauses (holds state).
//                 3. Once the counter reaches 'DELAY', 'dout' goes high.
//                 4. One-Shot nature: The pulse does NOT repeat until the
//                    system is reset again.
//
// Parameters:
//   DELAY : The number of clock cycles to wait before asserting 'dout'.
//   RZ    : Return-To-Zero Mode.
//           - 1 (Pulse Mode): 'dout' stays high for exactly 1 clock cycle,
//             then returns to 0.
//           - 0 (Step/Latch Mode): 'dout' goes high and stays high indefinitely.
//
// Inputs:
//   clk   : System Clock.
//   ena   : Enable signal.
//           - 1: Counter runs.
//           - 0: Counter pauses (freezes timing).
//   rst_n : Active-low asynchronous/synchronous reset.
//           - 0: Resets counter and output to 0.
//           - 1: Starts the sequence.
//
// Outputs:
//   dout  : The generated pulse or step signal.
//
// Usage Example:
//   // Create a strobe that fires 100 cycles after reset
//   PulseSignal #(.DELAY(100), .RZ(1)) u_startup_strobe (
//       .clk(clk), .ena(1'b1), .rst_n(rst_n), .dout(start_strobe)
//   );
//
//////////////////////////////////////////////////////////////////////////////////

module PulseSignal #(
    parameter int DELAY = 1,
    parameter bit RZ    = 1  // 1 = Pulse (1 cycle), 0 = Step (Latch High)
)
(
    input  logic clk,
    input  logic ena,
    input  logic rst_n,
    output logic dout
);

    // Calculate minimum bits needed to store (DELAY + 1)
    // We use DELAY+2 to safely cover the "stop" condition in the counter logic
    localparam int CNTWIDTH = $clog2(DELAY + 2);

    logic [CNTWIDTH-1:0] count;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            count <= '0;
            dout  <= 1'b0;
        end
        else if (ena) begin
            // Increment counter until it passes the target DELAY
            if (count <= DELAY)
                count <= count + 1'b1;

            // Output Logic
            if (count == DELAY)
                dout <= 1'b1;         // Fire pulse
            else if (RZ && (count > DELAY))
                dout <= 1'b0;         // Return to zero if RZ is set
        end
    end

endmodule
