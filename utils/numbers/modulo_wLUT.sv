//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : modulo_wLUT
// Date          : January 6, 2026
// Description   : Calculates (A % B) using a Look-Up Table (LUT).
//
//                 Key capabilities:
//                 1. Speed: Eliminates complex division logic. The result is
//                    retrieved instantly (Combinational Logic).
//                 2. Pre-calculation: The initial block calculates the remainders
//                    during synthesis/elaboration.
//                 3. Efficiency: Ideal for small bit-width inputs where standard
//                    modulo operators (%) would infer slow divider logic.
//
// Parameters:
//   WIDTH_INOUT : Bit width of the input data.
//                 WARNING: Keep small (< 10 bits). The LUT size grows exponentially.
//   MODULO_OF   : The divisor (e.g., 10, 60, etc.).
//
// Inputs:
//   i_data     : Input value to perform modulo on.
//
// Outputs:
//   o_data     : The remainder result (i_data % MODULO_OF).
//
// !!! DELAY = 0 (Purely Combinational)
//
// Usage Example:
//   modulo_wLUT #(
//       .WIDTH_INOUT(4),    // Input is 4 bits (0-15)
//       .MODULO_OF(10)      // Calculate % 10
//   ) u_mod_10 (
//       .i_data( counter_val ),
//       .o_data( mod_result  )
//   );
//////////////////////////////////////////////////////////////////////////////////

module modulo_wLUT #(
    parameter int WIDTH_INOUT  = 4,
    parameter int MODULO_OF    = 10
)(
    input  logic [WIDTH_INOUT-1:0] i_data,
    output logic [WIDTH_INOUT-1:0] o_data
);

    // 1. Calculate the total number of possible input values
    localparam int TABLEDEPTH = 1 << WIDTH_INOUT;

    // 2. Create the Table
    //    It must be large enough to hold an answer for EVERY possible input.
    logic [WIDTH_INOUT-1:0] modulo_LUT [TABLEDEPTH];

    // 3. Initialize the Table (Calculated at Synthesis Time)
    initial begin
        for (int i = 0; i < TABLEDEPTH; i++) begin
            modulo_LUT[i] = i % MODULO_OF;
        end
    end

    // 4. Look up the result
    assign o_data = modulo_LUT[i_data];

endmodule
