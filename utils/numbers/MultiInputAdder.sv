//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : MultiInputAdder_Pipeline
// Date          : November 19, 2025
// Description   : This module performs the summation of multiple input values
//                 using a balanced binary adder tree.
//
//                 Key capabilities:
//                 1. Pipelining: The module automatically inserts pipeline
//                    registers between adder stages to meet a target latency
//                    (OUTPUT_DELAY).
//                 2. Precision: The output width is automatically extended by
//                    $clog2(NUM_INPUT) bits to guarantee no overflow.
//                 3. Flexibility: Supports both signed and unsigned arithmetic
//                    and handles arbitrary input counts (even or odd).
//
// Parameters:
//   NUM_INPUT    : Number of input signals to sum.
//   WIDTH_IN     : Bit width of a single input signal.
//   IS_SIGNED    : 1 = Signed arithmetic (2's complement), 0 = Unsigned.
//   OUTPUT_DELAY : Target latency in clock cycles.
//                  - If 0: Purely combinational (0 clock cycle latency).
//                  - If >0: Pipelined with registers inserted to distribute
//                    logic delay across 'OUTPUT_DELAY' clock cycles.
//
// Inputs:
//   clk  : System Clock.
//   ena  : Clock Enable (Active High). Controls the pipeline registers.
//   din  : Array of inputs [NUM_INPUT] x [WIDTH_IN].
//
// Outputs:
//   dout : Full precision sum. Width = WIDTH_IN + $clog2(NUM_INPUT).
//
// Features:
//   - Configurable Pipeline Depth (Latency)
//   - Balanced Adder Tree structure for minimized logic delay
//   - Automatic Sign Extension / Zero Extension based on IS_SIGNED
//   - Efficient Logic Grouping: Automatically groups adder levels to fit
//     within the requested clock cycles
//   - No Overflow: Output width grows dynamically
//
// Usage Example:
//   MultiInputAdder #(
//       .NUM_INPUT(32),
//       .WIDTH_IN(16),
//       .IS_SIGNED(1),
//       .OUTPUT_DELAY(2) // Result appears 2 clocks later
//   ) u_adder (
//       .clk(clk),
//       .ena(1'b1),
//       .din(my_data_array),
//       .dout(sum_result)
//   );
//
//////////////////////////////////////////////////////////////////////////////////

module MultiInputAdder #(
    parameter int NUM_INPUT    = 2,
    parameter int WIDTH_IN     = 16,
    parameter bit IS_SIGNED    = 1,
    parameter int OUTPUT_DELAY = 1,

    // derived parameters
    parameter int WIDTH_OUT = WIDTH_IN + $clog2(NUM_INPUT)
)
(
    input  logic clk, ena,
    input  logic [WIDTH_IN -1:0] din [NUM_INPUT],
    output logic [WIDTH_OUT-1:0] dout
);

    generate
        // Check parameter validity
        if (WIDTH_IN <= 0) begin : gen_error_DATA_WIDTH_IN
            initial begin
                $error("DATA_WIDTH_IN must be > 0");
            end
        end
    endgenerate


    localparam int TotalLevels      = $clog2(NUM_INPUT);
    localparam int NumLevelPerCycle = (OUTPUT_DELAY > 0) ?
                        (TotalLevels + OUTPUT_DELAY - 1) / OUTPUT_DELAY : TotalLevels;


    //Array to hold results at every level of the tree
    logic [WIDTH_OUT-1:0] tree_nodes [TotalLevels+1][NUM_INPUT];


    //Level 0: Input Extension (Always Combinational)
    always_comb begin
        for (int i=0; i<NUM_INPUT; i++) begin
            if (!IS_SIGNED)
                tree_nodes[0][i] = {{(WIDTH_OUT-WIDTH_IN){1'b0}} , din[i]};
            else
                tree_nodes[0][i] = {{(WIDTH_OUT-WIDTH_IN){din[i][WIDTH_IN-1]}} , din[i]};
        end
    end


    generate
        genvar i_level, i_add;

        for (i_level=0; i_level<TotalLevels; i_level++) begin : gen_tree
            localparam int NumInput    = (NUM_INPUT + (1<<i_level) - 1) >> i_level;
            localparam int NumAdd      = NumInput >> 1;
            localparam bit PassThrough = NumInput[0] === 1;

            if ((OUTPUT_DELAY>0) && (i_level+1)%NumLevelPerCycle == 0) begin : gen_seq
                for (i_add=0; i_add<NumAdd; i_add++) begin : gen_seq_add
                    always_ff @(posedge clk) begin
                        if (ena) begin
                            tree_nodes[i_level+1][i_add] <= tree_nodes[i_level][2*i_add] +
                                                            tree_nodes[i_level][2*i_add+1];
                        end
                    end
                end

                if (PassThrough) begin : gen_seq_passthrough
                    always_ff @(posedge clk) begin
                        if (ena) begin
                            tree_nodes[i_level+1][NumAdd] <= tree_nodes[i_level][2*NumAdd];
                        end
                    end
                end
            end
            else begin : gen_comb
                for (i_add=0; i_add<NumAdd; i_add++) begin : gen_comb_add
                    always_comb begin
                        tree_nodes[i_level+1][i_add] = tree_nodes[i_level][2*i_add] +
                                                        tree_nodes[i_level][2*i_add+1];
                    end
                end

                if (PassThrough) begin : gen_comb_passthrough
                    always_comb begin
                        tree_nodes[i_level+1][NumAdd] = tree_nodes[i_level][2*NumAdd];
                    end
                end
            end
        end
    endgenerate



    assign dout = tree_nodes[TotalLevels][0];

endmodule
