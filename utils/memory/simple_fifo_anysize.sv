//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : simple_fifo_anysize
// Date          : January 5, 2026
// Description   : A synchronous First-In-First-Out (FIFO) buffer designed to
//                 support arbitrary storage depths.
//
//                 Unlike standard power-of-2 FIFOs, this module supports any
//                 integer size (e.g., 10, 13, 100) by handling pointer wrapping
//                 manually. It uses an internal counter to safely track the
//                 fill level, preventing ambiguity between "Full" and "Empty"
//                 states in circular buffering.
//
// Parameters:
//   FIFO_SIZE    : Depth of the FIFO (Number of slots).
//                  * Can be ANY positive integer (Odd, Even, Non-Power-of-2).
//   DATA_WIDTH   : Width of the input/output data bus.
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
//   - Arbitrary Depth Support (No power-of-2 restriction).
//   - Counter-based status logic for robust Full/Empty detection.
//   - Standard 1-cycle read latency.
//   - Explicit "Ready" and "Valid" handshaking signals.
//
// !!! DELAY = 1 (Standard Read Request Mode)
//
// Usage:
//   simple_fifo_anysize #(
//       .FIFO_SIZE(13),
//       .DATA_WIDTH(16)
//   ) u_fifo (
//       .i_clk(clk),
//       .i_ena(1'b1),
//       .i_rst_n(rst_n),
//       ...
//   );
//
//////////////////////////////////////////////////////////////////////////////////

module simple_fifo_anysize #(
    parameter int FIFO_SIZE    = 8,
    parameter int DATA_WIDTH   = 16,

    // derived parameters
    parameter int FIFO_SIZE_WIDTH = $clog2(FIFO_SIZE + 1),
    parameter int FIFO_PTR_WIDTH  = $clog2(FIFO_SIZE)
)
(
    input  logic i_clk, i_ena, i_rst_n, i_rd_req, i_wr_req,
    input  logic [DATA_WIDTH-1:0] i_data,
    output logic [DATA_WIDTH-1:0] o_data,
    output logic o_full, o_empty, o_ready, o_valid,
    output logic [FIFO_SIZE_WIDTH-1:0] o_current_sz
);

    logic [DATA_WIDTH-1:0] fifo_mem [FIFO_SIZE];
    logic [FIFO_SIZE_WIDTH-1:0] fifo_count;
    logic [FIFO_PTR_WIDTH -1:0] rd_ptr, wr_ptr; //Read/Write pointer


    assign o_current_sz = fifo_count;
    assign o_full       = (fifo_count == FIFO_SIZE);
    assign o_empty      = (fifo_count == 0);
    assign o_ready      = !o_full;


    logic do_read, do_write;
    //
    assign do_read  = i_rd_req && !o_empty; // Only read  if not empty
    assign do_write = i_wr_req && !o_full;  // Only write if not full


    always_ff @ (posedge i_clk) begin
        if (i_rst_n == 0) begin
            rd_ptr      <= '0;
            wr_ptr      <= '0;
            fifo_count  <= '0;
            //
            o_data      <= '0;
            o_valid     <= 1'b0;
        end
        else begin
            if (i_ena) begin
                //Read process
                if (do_read) begin
                    o_data  <= fifo_mem[rd_ptr];
                    o_valid <= 1'b1;

                    if (rd_ptr == FIFO_SIZE-1) begin
                        rd_ptr <= 0;
                    end
                    else begin
                        rd_ptr  <= rd_ptr + 1;
                    end
                end
                else begin
                    o_valid <= 1'b0;
                end

                //Write process
                if (do_write) begin
                    fifo_mem[wr_ptr] <= i_data;

                    if (wr_ptr == FIFO_SIZE-1) begin
                        wr_ptr <= 0;
                    end
                    else begin
                        wr_ptr  <= wr_ptr + 1;
                    end
                end

                //Updating fifo_count
                if (do_read && !do_write) begin
                    fifo_count <= fifo_count - 1;
                end
                else if (!do_read && do_write) begin
                    fifo_count <= fifo_count + 1;
                end
            end
        end
    end
endmodule
