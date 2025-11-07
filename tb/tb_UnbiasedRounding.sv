`timescale 1ns/1ps

module tb_UnbiasedRounding;

    // =============================================================
    // Parameters
    // =============================================================
    localparam int  WIDTH_IN   = 32;
    localparam int  WIDTH_OUT  = 16;
    localparam int  DIFF       = WIDTH_IN - WIDTH_OUT;
    localparam time CLK_PERIOD = 10ns;
    localparam int  NUM_TESTS  = 2^32-1; // reduce for faster simulation

    // =============================================================
    // DUT signals
    // =============================================================
    logic clk, ena;
    logic signed [WIDTH_IN-1:0]  din;
    logic signed [WIDTH_OUT-1:0] dout;

    // Control parameters
    bit IS_SIGNED;
    bit IS_FRACTION;

    // =============================================================
    // Instantiate DUT
    // =============================================================
    UnbiasedRounding #(
        .WIDTH_IN   (WIDTH_IN),
        .WIDTH_OUT  (WIDTH_OUT),
        .IS_SIGNED  (1'b1),
        .IS_FRACTION(1'b0)
    ) dut (
        .clk(clk),
        .ena(ena),
        .din(din),
        .dout(dout)
    );

    // =============================================================
    // Clock generation
    // =============================================================
    always #(CLK_PERIOD/2) clk = ~clk;

    // =============================================================
    // Helper task: reference rounding using real arithmetic
    // =============================================================
    function automatic logic signed [WIDTH_OUT-1:0]
        ref_round(input int din_i, input bit signed_mode);
        real val, scaled, rounded;
        int  result;
        real scale = 2.0 ** DIFF;

        // Convert integer input to real
        val = din_i;

        scaled = val / scale;

        // unbiased rounding (round-half-to-even)
        rounded = $floor(scaled + 0.5);
        if ((scaled - $floor(scaled)) == 0.5) begin
            if ($floor(scaled) % 2 != 0)
                rounded = $floor(scaled); // tie-to-even
        end

        result = $rtoi(rounded); // convert back to int

        // clip to output range
        if (signed_mode) begin
            if (result >  (2**(WIDTH_OUT-1)-1))
                result =  (2**(WIDTH_OUT-1)-1);
            if (result < -(2**(WIDTH_OUT-1)))
                result = -(2**(WIDTH_OUT-1));
        end else begin
            if (result > (2**WIDTH_OUT - 1))
                result = (2**WIDTH_OUT - 1);
            if (result < 0)
                result = 0;
        end

        return logic'(result);
    endfunction

    // =============================================================
    // Main test
    // =============================================================
    initial begin
        clk = 0;
        ena = 1;
        din = 0;

        $display("==============================================");
        $display(" UnbiasedRounding 32->16 Self-Check Testbench ");
        $display("==============================================");

        // Sweep through all parameter combinations
        foreach ({IS_SIGNED, IS_FRACTION}) begin end // to define outside loop

        for (int s = 0; s < 2; s++) begin
            IS_SIGNED = s;
            for (int f = 0; f < 2; f++) begin
                IS_FRACTION = f;
                dut.IS_SIGNED    = IS_SIGNED;
                dut.IS_FRACTION  = IS_FRACTION;

                $display("\nMode: IS_SIGNED=%0d, IS_FRACTION=%0d", IS_SIGNED, IS_FRACTION);

                for (int i = 0; i < NUM_TESTS; i++) begin
                    // Generate random test input
                    if (IS_SIGNED)
                        din = $urandom_range(-(1 << (WIDTH_IN-1)), (1 << (WIDTH_IN-1))-1);
                    else
                        din = $urandom();

                    // Apply input and wait for output
                    @(posedge clk);
                    @(posedge clk);

                    // Compute reference result
                    logic signed [WIDTH_OUT-1:0] ref_out;
                    ref_out = ref_round(din, IS_SIGNED, IS_FRACTION);

                    // Compare DUT vs reference
                    if (dout !== ref_out) begin
                        $error("Mismatch detected! Mode(S=%0d,F=%0d) din=%0d (0x%h) -> DUT=%0d (0x%h) Expected=%0d (0x%h)",
                               IS_SIGNED, IS_FRACTION, din, din, dout, dout, ref_out, ref_out);
                        $fatal;
                    end

                    // Show a few samples
                    if (i < 5)
                        $display("din=%0d dout=%0d ref=%0d", din, dout, ref_out);
                end
                $display("Mode (S=%0d,F=%0d) PASSED ✓", IS_SIGNED, IS_FRACTION);
            end
        end

        $display("\n==============================================");
        $display(" All tests PASSED! ");
        $display("==============================================");
        $finish;
    end

endmodule
