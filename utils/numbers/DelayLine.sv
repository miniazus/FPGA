//////////////////////////////////////////////////////////////////////////////////
// Support by: Google Gemini
// Module Name   : DelayLine
// Date          : November 19, 2025
// Description   : A universal, parameterizable signal delay block implementing 
//                 a z^-n transfer function.
//
//                 Key capabilities:
//                 1. Universal Mode: Automatically generates either a 
//                    combinational wire (Mode 1) or a sequential shift register 
//                    (Mode 2) based on the DELAY parameter.
//                 2. Pipeline Control: Includes an enable signal to pause/hold 
//                    the delay line contents.
//                 3. Synthesis Optimized: Uses efficient shift-register inference 
//                    compatible with FPGA logic elements (LEs/ALMs).
//
// Parameters:
//   WIDTH  : Bit width of the input/output signal.
//   DELAY  : Number of clock cycles to delay the signal (z^-n).
//            - If <= 0: Pass-through mode (Wire). 0 Latency.
//              (clk and ena are ignored in this mode).
//            - If > 0 : Registered mode. Creates a chain of 'DELAY' registers.
//
// Inputs:
//   clk  : System Clock (Required if DELAY > 0).
//   ena  : Clock Enable.
//          - 1: Normal operation (shift data).
//          - 0: Freeze/Pause data (maintain current state).
//   din  : Input signal of 'WIDTH' bits.
//
// Outputs:
//   dout : Delayed output signal.
//
// Features:
//   - Seamless switching between Combinational and Sequential logic
//   - Parameterizable width and depth
//   - Active-high enable for pipeline stalling mechanisms
//   - Robust handling of DELAY=0 case (prevents synthesis errors)
//
// Usage Example:
//   // Delay a valid signal by 3 clock cycles
//   DelayLine #(.WIDTH(1), .DELAY(3)) u_valid_dly (
//       .clk(clk),
//       .ena(1'b1),
//       .din(data_valid),
//       .dout(data_valid_d3)
//   );
//
//////////////////////////////////////////////////////////////////////////////////

module DelayLine #(
    parameter int WIDTH = 16, // Width of the signal
    parameter int DELAY = 1   // 'n' delay cycles (z^-n)
)
(
    input  logic             clk,
    input  logic             ena,   // Usually 1, use 0 to pause the delay
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout
);

    generate
        // CASE 1: No Delay (Pass through)
        if (DELAY <= 0) begin : gen_pass
            assign dout = din;
        end
        // CASE 2: Delay exists
        else begin : gen_delay
            // Define the memory for the shift register
            logic [WIDTH-1:0] shift_reg [DELAY];

            always_ff @(posedge clk) begin
                if (ena) begin
                    // 1. Load the new input into the start of the chain
                    shift_reg[0] <= din;

                    // 2. Shift everything else forward by one step
                    for (int i = 1; i < DELAY; i++) begin
                        shift_reg[i] <= shift_reg[i-1];
                    end
                end
            end

            // 3. The output is the very last value in the chain
            assign dout = shift_reg[DELAY-1];
        end
    endgenerate

endmodule
