//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : RoundRobin_Selection
// Date          : January 9, 2026
// Description   : Implements a high-speed Round Robin Arbiter using One-Hot masking.
//
//                 Key capabilities:
//                 1. True Round-Robin: Ensures fair access by rotating priority
//                    relative to the last granted index.
//                 2. Optimized Logic: Uses 2's complement math [-(x << 1)] to
//                    replace slow loops, utilizing FPGA Carry Chains for speed.
//                 3. One-Hot Interface: Both input requests and output grants
//                    use bit-mapped vectors (efficient for hardware).
//
// Parameters:
//   UPTO       : Total number of input requestors (e.g., 100).
//
// Inputs:
//   i_clk          : System clock.
//   i_rst_n        : Active low reset.
//   i_ena          : Enable signal to update the grant.
//   i_input_enable : Request Bitmap (1 = Requesting, 0 = Idle).
//
// Outputs:
//   o_select       : One-Hot vector indicating the granted agent.
//                    (e.g., 8'b0000_0100 means Agent 2 is granted).
//
// !!! Performance: Optimized for < 200 MHz on standard FPGAs (Width=100)
// !!! Delay = 0
//
// Usage Example:
//   RoundRobin_Selection #(
//       .UPTO(100)
//   ) u_rr (
//       .i_clk         (clk),
//       .i_rst_n       (i_rst_n),
//       .i_ena         (i_ena),
//       .i_input_enable(request_bus), // Active: Agent 0, 2, 5...
//       .o_select      (grant_bus  ), // Result: One-Hot Grant
//   );
//////////////////////////////////////////////////////////////////////////////////

module RoundRobin_Selection #(
    parameter int UPTO = 100
)
(
    input  logic            i_clk,
    input  logic            i_rst_n,
    input  logic            i_ena,
    input  logic [UPTO-1:0] i_input_enable,

    output logic [UPTO-1:0] o_select // One-Hot Output
    // output logic [$clog2(UPTO)-1:0] o_select_num  // Binary Number Output
);

    logic [UPTO-1:0] idx_ff, idx_com;

    always_ff @ (posedge i_clk) begin
        if (!i_rst_n) begin
            idx_ff <= '0;
        end
        else begin
            if (i_ena) begin
                idx_ff <= idx_com;
            end
        end
    end


    logic [UPTO-1:0] BitMasked_gt_idx_ff;
    logic [UPTO-1:0] ListOfIdx_gt_idx_ff;

    always_comb begin
        BitMasked_gt_idx_ff = -(idx_ff << 1);
        ListOfIdx_gt_idx_ff = BitMasked_gt_idx_ff & i_input_enable;

        idx_com = '0;
        //
        if (|ListOfIdx_gt_idx_ff) begin
            idx_com = ListOfIdx_gt_idx_ff & (-ListOfIdx_gt_idx_ff);
        end
        else begin
            idx_com = i_input_enable & (-i_input_enable);
        end
    end

    assign o_select = idx_ff;


    // always_comb begin
    //     o_select_num = '0;
    //     //
    //     for (int i=0; i<UPTO; i++) begin
    //         if (idx_ff[i]==1'b1) begin
    //             o_select_num = i[$clog2(UPTO)-1:0];
    //         end
    //     end
    // end

endmodule
