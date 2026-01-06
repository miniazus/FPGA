//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : simple_fifo_log2size
// Date          : January 5, 2026
// Description   : High-performance synchronous FIFO optimized for Power-of-2 
//                 depths.
//
//                 This module eliminates the internal up/down counter used in
//                 generic FIFOs. Instead, it uses "Pointer Arithmetic" with
//                 an extra status bit (Lap Bit) to detect Full/Empty conditions.
//                 This results in higher maximum frequency (Fmax) and lower
//                 resource usage for standard buffer sizes (8, 16, 32, etc.).
//
// Parameters:
//   FIFO_SIZE_LOG2 : The logarithm of the FIFO depth.
//                    Examples:
//                    - 3 => Size = 2^3 = 8
//                    - 4 => Size = 2^4 = 16
//                    - 5 => Size = 2^5 = 32
//   DATA_WIDTH     : Width of the input/output data bus.
//
// Inputs:
//   i_clk    : System Clock.
//   i_ena    : Global Enable (Active High).
//   i_rst_n  : Synchronous Reset (Active Low).
//   i_rd_req : Read Request.
//   i_wr_req : Write Request.
//   i_data   : Input Data [DATA_WIDTH-1:0].
//
// Outputs:
//   o_data       : Output Data (Valid 1 clock cycle after read request).
//   o_full       : High when FIFO is full (Writes ignored).
//   o_empty      : High when FIFO is empty (Reads ignored).
//   o_ready      : High when FIFO can accept new data (!o_full).
//   o_valid      : High when o_data contains valid read data.
//   o_current_sz : Current number of items in the FIFO.
//
// Features:
//   - Zero counter logic (Status derived purely from pointers).
//   - Optimized for high-frequency FPGA/ASIC timing.
//   - Natural binary overflow handling (no comparators for wrapping).
//
// !!! DELAY = 1 (Standard Read Request Mode)
//
// Usage:
//   simple_fifo_log2size #(
//       .FIFO_SIZE_LOG2(4), // Depth = 16
//       .DATA_WIDTH(16)
//   ) u_fast_fifo ( ... );
//
//////////////////////////////////////////////////////////////////////////////////

module simple_fifo_log2size #(
    parameter int FIFO_SIZE_LOG2 = 3, // Default Size = 2^3 = 8
    parameter int DATA_WIDTH     = 16
)
(
    input  logic i_clk, i_ena, i_rst_n, i_rd_req, i_wr_req,
    input  logic [DATA_WIDTH-1:0] i_data,

    output logic [DATA_WIDTH-1:0] o_data,
    output logic o_full, o_empty, o_ready, o_valid,

    // Output size needs 1 extra bit to hold the value "Size"
    // e.g., Size 8 (3 bits) needs 4 bits to store the number 8.
    output logic [FIFO_SIZE_LOG2:0] o_current_sz
);

    localparam int FIFOSIZE = 1 << FIFO_SIZE_LOG2;

    logic [DATA_WIDTH-1:0]     fifo_mem [FIFOSIZE];

    // Pointers have 1 extra "Lap Bit" (MSB)
    logic [FIFO_SIZE_LOG2:0]   rd_ptr, wr_ptr;

    // -----------------------------------------------------------
    // Status Logic (No Counter Needed!)
    // -----------------------------------------------------------
    // Size is purely the difference between pointers.
    // The extra bit handles the wrap-around math automatically.
    assign o_current_sz = wr_ptr - rd_ptr;
    assign o_empty      = (rd_ptr == wr_ptr);

    // Full if MSB is different (Lap) but LSBs are same (Index)
    assign o_full       = (wr_ptr[FIFO_SIZE_LOG2] != rd_ptr[FIFO_SIZE_LOG2]) &&
                          (wr_ptr[FIFO_SIZE_LOG2-1:0] == rd_ptr[FIFO_SIZE_LOG2-1:0]);

    assign o_ready      = !o_full;


    logic do_read, do_write;
    assign do_read  = i_rd_req && !o_empty;
    assign do_write = i_wr_req && !o_full;


    always_ff @ (posedge i_clk) begin
        if (i_rst_n == 0) begin
            rd_ptr  <= '0;
            wr_ptr  <= '0;
            o_data  <= '0;
            o_valid <= 1'b0;
        end
        else begin
            if (i_ena) begin
                // --- Read Process ---
                if (do_read) begin
                    // IMPORTANT: Index memory using ONLY the lower bits
                    o_data  <= fifo_mem[ rd_ptr[FIFO_SIZE_LOG2-1:0] ];
                    o_valid <= 1'b1;
                    rd_ptr  <= rd_ptr + 1;
                end
                else begin
                    o_valid <= 1'b0;
                end

                // --- Write Process ---
                if (do_write) begin
                    // IMPORTANT: Index memory using ONLY the lower bits
                    fifo_mem[ wr_ptr[FIFO_SIZE_LOG2-1:0] ] <= i_data;
                    wr_ptr  <= wr_ptr + 1;
                end
            end
        end
    end

endmodule
