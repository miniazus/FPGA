module CIC_Decimation #(
    parameter int WIDTH_IN  = 16,
    parameter int NUM_STAGE = 5,
    parameter int MAX_RATE  = 16,
    //
    parameter int WIDTH_OUT = WIDTH_IN + NUM_STAGE * $clog2(MAX_RATE)
)
(
    input  clk, ena, rst_n,
    input  logic signed [WIDTH_IN-1:0]  din_odd, din_even,
    input  [7:0] rate,
    output logic signed [WIDTH_OUT-1:0] dout,
    output vld, rdy
);

    generate
        // Check parameter validity
        if (NUM_STAGE < 1) begin : gen_error_NUM_STAGE
            initial begin
                $error("NUM_STAGE must be > 0");
            end
        end

        if (RATE > MAX_RATE) begin : gen_error_MAX_RATE
            initial begin
                $error("RATE must be <= MAX_RATE");
            end
        end
    endgenerate

    localparam int BITEXTENSION = WIDTH_IN + NUM_STAGE * $clog2(MAX_RATE);

    logic signed  [BITEXTENSION-1:0] acc_stage_integrator   [NUM_STAGE];
    logic signed  [BITEXTENSION-1:0] integrator_stage_i_odd [NUM_STAGE];
    logic signed  [BITEXTENSION-1:0] integrator_stage_i_eve [NUM_STAGE];
    logic signed  [BITEXTENSION-1:0] integrator_stage_o_odd [NUM_STAGE];
    logic signed  [BITEXTENSION-1:0] integrator_stage_o_eve [NUM_STAGE];
    logic signed  [BITEXTENSION-1:0] integrator_o_eve, integrator_o_odd;

    // Step 1: Integrator
    assign integrator_stage_i_odd[0] = {{(BITEXTENSION-WIDTH_IN){din_odd [WIDTH_IN-1]}}, din_odd };
    assign integrator_stage_i_eve[0] = {{(BITEXTENSION-WIDTH_IN){din_even[WIDTH_IN-1]}}, din_even};

    genvar i;
    //
    generate
        for (i=1; i<NUM_STAGE; i++) begin : gen_wiring_integrator_stage_out_in
            assign integrator_stage_i_odd[i] = integrator_stage_o_odd[i-1];
            assign integrator_stage_i_eve[i] = integrator_stage_o_eve[i-1];
        end
    endgenerate

    generate
        for (i=0; i<NUM_STAGE; i++) begin : gen_integrator_stage
            assign integrator_stage_o_eve[i] = acc_stage_integrator[i]  +integrator_stage_i_eve[i];
            assign integrator_stage_o_odd[i] = integrator_stage_o_eve[i]+integrator_stage_i_odd[i];

            always_ff @(posedge clk) begin
                if (!rst_n) begin
                    acc_stage_integrator[i] <= {(BITEXTENSION-1){0}};
                end
                else if (ena) begin
                    acc_stage_integrator[i] <= integrator_stage_o_eve[i];
                end
            end
        end
    endgenerate

    assign integrator_o_eve = integrator_stage_o_eve[NUM_STAGE-1];
    assign integrator_o_odd = integrator_stage_o_odd[NUM_STAGE-1];

    logic integrator_o_rdy;
    //
    PulseSignal #(.DELAY(NUM_STAGE), .RZ(0))
        u_pulse_signal (.clk(clk), .ena(ena), .rst_n(rst_n), .dout(integrator_o_rdy));

    logic downsample_i_ena;
    assign downsample_i_ena = ena & integrator_o_rdy;

    // Step 2: Downsample
    logic [8:0] count_down;
    logic down_valid;
    logic signed [BITEXTENSION-1:0] down_o;

    logic [8:0] next_count_down;
    assign next_count_down = count_down + 2;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            count_down  <= 8'd0;
            down_valid  <= 1'b0;
            down_o      <= {(BITEXTENSION-1){0}};
        end
        else if (downsample_i_ena) begin
            // --- 1. OUTPUT LOGIC
            // Case A: Start of Bin (Always Even)
            if (count_down == 0) begin
                down_o      <= integrator_stage_o_eve[NUM_STAGE-1];
                down_valid  <= 1;
            end
            // Case B: End of Bin (Always Odd)
            else if (next_count_down > rate) begin
                down_valid <= 1;
                down_o     <= integrator_stage_o_odd[NUM_STAGE-1];
            end
            // Case C: No Hit
            else
                down_valid <= 0;

            // --- 2. COUNTER LOGIC
            if (next_count_down >= rate)
                count_down <= next_count_down - rate;
            else
                count_down <= next_count_down;
        end
        else
            down_valid <= 0;
    end


    //Step 3: The Comb Filter (Differentiation) (Slow Domain)
    logic signed  [BITEXTENSION-1:0] acc_stage_comb[NUM_STAGE];
    logic signed  [BITEXTENSION-1:0] comb_stage_i  [NUM_STAGE];
    logic signed  [BITEXTENSION-1:0] comb_stage_o  [NUM_STAGE];
    logic signed  [BITEXTENSION-1:0] comb_o;
    logic                            comb_valid;
    logic                            comb_o_rdy;

    assign comb_stage_i[0] = down_o;

    generate
        for (i=1; i<NUM_STAGE; i++) begin : gen_wiring_comb_stage_out_in
            assign comb_stage_i[i] = comb_stage_o[i-1];
        end

        for (i=0; i<NUM_STAGE; i++) begin : gen_comb_stage
            assign comb_stage_o[i] = comb_stage_i[i] - acc_stage_comb[i];

            always_ff @(posedge clk) begin
                if (~rst_n) begin
                    acc_stage_comb[i] <= {(BITEXTENSION-1){0}};
                end
                else if (down_valid) begin
                    acc_stage_comb[i] <= comb_stage_i[i];
                end
            end
        end
    endgenerate

    assign comb_o = comb_stage_o[NUM_STAGE-1];

    //
    PulseSignal #(.DELAY(NUM_STAGE), .RZ(0))
        u_pulse_signal (.clk(clk), .ena(down_valid), .rst_n(rst_n), .dout(comb_o_rdy));

    assign comb_valid = comb_o_rdy & down_valid;


    assign dout = comb_o;
    assign vld  = comb_valid;
    assign rdy  = comb_o_rdy;
endmodule

// Parallel Integrator -----------------------------------------------------
//
//                Input Even                  Input Odd
//                (din_even)                  (din_odd)
//                     |                           |
//                     |                           |
//                     v                           v
//               +-----------+               +-----------+
// Old History ->|  ADDER 1  |----(wire)---->|  ADDER 2  |-----> Result Odd
// (acc_stage_integrator)   +-----------+               +-----------+       (To Next Stage)
//      ^              |                           |
//      |              |                           |
//      |              v                           |
//      |         Result Even                      |
//      |      (To Decimator Mux)                  |
//      |                                          |
//      |                                          |
//      +------------------------------------------+
//                     |
//                     v
//               +-----------+
//               |  REGISTER |  (Updates at posedge clk)
//               +-----------+
//
//
//[ Stage 0 ]  ===>  [ Stage 1 ]  ===>  [ Stage 2 ] ...