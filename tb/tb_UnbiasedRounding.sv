`timescale 1ns/1ps

module tb_UnbiasedRounding;

    localparam int  WIDTH_IN    = 32;
    localparam int  WIDTH_OUT   = 16;
    localparam int  DIFF        = WIDTH_IN - WIDTH_OUT;
    localparam time CLK_PERIOD  = 10ns;
    //
    localparam longint  STEP    = (64'd1 << WIDTH_IN) / 100;

    // DUT signals
    logic clk, ena;
    logic        [WIDTH_IN-1:0]  din;
    logic signed [WIDTH_OUT-1:0] dout_signed;
    logic        [WIDTH_OUT-1:0] dout_unsigned;
    // Control parameters
    bit IS_SIGNED;

    // Instantiate DUT
    UnbiasedRounding #(
        .WIDTH_IN(WIDTH_IN),
        .WIDTH_OUT(WIDTH_OUT),
        .IS_SIGNED(1'b1)
    ) dut_signed (
        .clk(clk),
        .ena(ena),
        .din(din),
        .dout(dout_signed)
    );

    UnbiasedRounding #(
        .WIDTH_IN(WIDTH_IN),
        .WIDTH_OUT(WIDTH_OUT),
        .IS_SIGNED(1'b0)
    ) dut_unsigned (
        .clk(clk),
        .ena(ena),
        .din(din),
        .dout(dout_unsigned)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // ------------------------------------------------------------
    // Reference rounding function (bit-accurate)
    // ------------------------------------------------------------
    function automatic void ref_round (
        input  bit                   is_signed,
        input  logic [WIDTH_IN-1:0]  din,
        output logic [WIDTH_OUT-1:0] dout);

        real scale, val, rounded_val, minval, maxval;
        real normalized;
        real floor_v, frac_v, added_num;
        longint result;
        int DIFF;

        DIFF = WIDTH_IN - WIDTH_OUT;

        // Compute scale factor (equivalent to shifting right DIFF bits)
        scale = (DIFF > 0) ? (1.0 * (1 << DIFF)) : 1.0;

        // Convert input to real (signed or unsigned)
        if (is_signed)
            val = $itor($signed(din));
        else
            val = $itor($unsigned(din));

        // Normalize to output bit width
        normalized = val / scale;

        // --- Unbiased rounding (round-half-to-even) ---
        floor_v = $floor(normalized);
        frac_v  = normalized - floor_v;

        if (is_signed  && val<0)
            added_num = -1.0;
        else
            added_num = 1.0;

        if (frac_v > 0.5)
            rounded_val = floor_v + added_num;
        else if (frac_v < 0.5)
            rounded_val = floor_v;
        else
            // exactly halfway (x.5): round to even
            rounded_val = (floor_v/2.0 == $floor(floor_v/2.0)) ? floor_v : floor_v + added_num;

        // $display("S=%0d, din=%0d, val=%0f, scale=%0f, normalized=%0f, rounded_val=%0f",
        //             is_signed, din, val, scale, normalized, rounded_val);


        // --- Saturation ---
        if (is_signed) begin
            minval = -(1 << (WIDTH_OUT - 1));
            maxval =  (1 << (WIDTH_OUT - 1)) - 1;
        end else begin
            minval = 0;
            maxval = (1 << WIDTH_OUT) - 1;
        end

        if (rounded_val > maxval)
            result = maxval;
        else if (rounded_val < minval)
            result = minval;
        else
            result = int'(rounded_val);


        // $display("rounded_val *= scale =%0f, minval=%0f, maxval=%0f, result=%0f",
        //             rounded_val,minval,maxval,result);

        if (is_signed)
            if (din[WIDTH_IN-1] === 1)
                dout = result[63-:WIDTH_OUT];
            else
                dout = result[WIDTH_OUT-1:0];
        else
            dout = result[WIDTH_OUT-1:0];

    endfunction


    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------

    initial begin
        logic [WIDTH_OUT-1:0] expected;
        logic [WIDTH_OUT-1:0] dout;
        //logic [WIDTH_IN-1:0]  din;
        int i;  // loop counter
        int s;  // mode selector

        clk = 0;
        ena = 1;

        $display("==============================================");
        $display(" Testing UnbiasedRounding 32->16 bit ");
        $display("==============================================");

        for (din=1; din!=0; din++) begin
            // Wait for DUT output
            @(posedge clk);
            @(posedge clk);

            // Compute expected output --- UNSIGNED CASE
            ref_round(0,din,expected);
            // Compare
            if (dout_unsigned !== expected) begin
                $error("Mismatch! Mode=Unsigned din=%0d dout=%0d expected=%0d",
                        din, dout_unsigned, expected);
                $fatal;
            end

            // Compute expected output --- SIGNED CASE
            ref_round(1,din,expected);
            // Compare
            if (dout_signed !== expected) begin
                $error("Mismatch! Mode=Signed din=%0d dout=%0d expected=%0d",
                        din, dout_signed, expected);
                $fatal;
            end

            // Print progress every 1%
            if ((din % STEP)==0)
                $display("Progress: %0d%% (%0d / %0d)",
                        din/STEP,
                        longint'(din),
                        longint'(64'd1 << WIDTH_IN));
        end

        $display("PASSED");
        $display("\nAll tests passed!");
        $finish;
    end

endmodule
