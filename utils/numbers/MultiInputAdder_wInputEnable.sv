//////////////////////////////////////////////////////////////////////////////////
// Company/Author: Viet Ha Nguyen
// Module Name   : MultiInputAdder_wInputEnable
// Date          : November 19, 2025
// Description   : A pipelined, balanced binary adder tree for summing multiple
//                 inputs with dynamic masking control.
//
//                 Key capabilities:
//                 1. Input Masking: The 'input_enable' bitmask allows dynamic
//                    selection of which inputs are included in the sum. Disabled
//                    inputs are treated as zero.
//                 2. Pipelining: Automatically inserts pipeline registers between
//                    adder stages to meet the target 'OUTPUT_DELAY'.
//                 3. Precision: Output width is automatically expanded by
//                    $clog2(NUM_INPUT) to guarantee no overflow.
//                 4. Flexibility: Supports Signed/Unsigned arithmetic and any
//                    number of inputs (arbitrary even/odd counts).
//
// Parameters:
//   NUM_INPUT    : Total number of input ports available.
//   WIDTH_IN     : Bit width of a single input signal.
//   IS_SIGNED    : 1 = Signed arithmetic (2's complement), 0 = Unsigned.
//   OUTPUT_DELAY : Target latency in clock cycles.
//                  - 0: Combinational output (0 clock cycle latency).
//                  - >0: Pipelined output distributed over 'OUTPUT_DELAY' cycles.
//
// Inputs:
//   clk          : System Clock.
//   ena          : Clock Enable (Active High). Freezes pipeline if low.
//   din          : Array of inputs [NUM_INPUT] x [WIDTH_IN].
//   input_enable : [NUM_INPUT-1:0] Bitmask to control participation in the sum.
//                  - Bit[i] = 1: din[i] is added.
//                  - Bit[i] = 0: din[i] is ignored (treated as 0).
//
// Outputs:
//   dout         : Full precision sum. Width = WIDTH_IN + $clog2(NUM_INPUT).
//
// Features:
//   - Dynamic Input Gating: Ignore specific channels without changing parameters.
//   - Balanced Adder Tree: Logarithmic logic depth for high-speed performance.
//   - Automatic Sign/Zero Extension: Handled internally based on 'IS_SIGNED'.
//   - Configurable Pipeline: Groups adder levels to fit timing constraints.
//
// Usage Example:
//   MultiInputAdder_wInputEnable #(
//       .NUM_INPUT(32),
//       .WIDTH_IN(16),
//       .IS_SIGNED(1),
//       .OUTPUT_DELAY(2)
//   ) u_adder (
//       .clk(sys_clk),
//       .ena(1'b1),
//       .din(sensor_data_array),
//       .input_enable(valid_sensor_mask),
//       .dout(total_sum)
//   );
//
//////////////////////////////////////////////////////////////////////////////////

module MultiInputAdder_wInputEnable #(
    parameter int NUM_INPUT    = 8,
    parameter int WIDTH_IN     = 16,
    parameter bit IS_SIGNED    = 1,
    parameter int OUTPUT_DELAY = 1,

    // derived parameters
    parameter int WIDTH_OUT = WIDTH_IN + $clog2(NUM_INPUT)
)
(
    input  logic clk, ena,
    input  logic [WIDTH_IN -1:0] din [NUM_INPUT],
    input  logic [NUM_INPUT-1:0] input_enable,
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
            if (!IS_SIGNED) begin
                if (input_enable[i] == 1'b1)
                    tree_nodes[0][i] = {{(WIDTH_OUT-WIDTH_IN){1'b0}} , din[i]};
                else
                    tree_nodes[0][i] = {(WIDTH_IN){1'b0}};
            end
            else begin
                if (input_enable[i] == 1'b1)
                    tree_nodes[0][i] = {{(WIDTH_OUT-WIDTH_IN){din[i][WIDTH_IN-1]}} , din[i]};
                else
                    tree_nodes[0][i] = {(WIDTH_IN){1'b0}};
            end
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
