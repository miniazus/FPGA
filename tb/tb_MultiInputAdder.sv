`timescale 1ns/1ps

module tb_MultiInputAdder;
    localparam longint NumTestCase = 1_00_000_000;

    localparam int NUMINPUT = 45;
    localparam int WIDTHIN  = 16;
    localparam int OUTDELAY = 5;

    localparam time CLKPERIOD  = 10ns;

    localparam int WIDTHOUT = WIDTHIN + $clog2(NUMINPUT);

    localparam longint Step = NumTestCase / 100;

    //DUT signal
    logic clk, ena;
    logic [WIDTHIN -1:0] din [NUMINPUT];
    logic [WIDTHOUT-1:0] dout_signed, dout_unsigned;

    // Instantiate DUT
    MultiInputAdder #(
                    .NUM_INPUT(NUMINPUT),
                    .WIDTH_IN(16),
                    .IS_SIGNED(0),
                    .OUTPUT_DELAY(OUTDELAY))
            u_MultiInputAdder_unsigned (
                    .clk(clk),
                    .ena(ena),
                    .din(din),
                    .dout(dout_unsigned));

    MultiInputAdder #(
                    .NUM_INPUT(NUMINPUT),
                    .WIDTH_IN(16),
                    .IS_SIGNED(1),
                    .OUTPUT_DELAY(OUTDELAY))
            u_MultiInputAdder_signed (
                    .clk(clk),
                    .ena(ena),
                    .din(din),
                    .dout(dout_signed));

    // Clock generation
    always #(CLKPERIOD/2) clk = ~clk;

    // Reference function (bit-accurate)
    function automatic logic [WIDTHOUT-1:0] ref_adder (
        input  bit                   is_signed,
        input  logic [WIDTHIN -1:0] din [NUMINPUT]);

        real ref_dout = 0;
        logic signed [WIDTHOUT-1:0] ref_dout_signed;

        for (int i=0; i<NUMINPUT; i++) begin
            if (is_signed)
                ref_dout += $itor($signed(din[i]));
            else
                ref_dout += $itor($unsigned(din[i]));
        end

        if (is_signed)
            ref_dout_signed = ref_dout;
        else
            return ref_dout;

        return ref_dout_signed;
    endfunction


    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------
    initial begin
        longint i;
        int ii;
        string din_str;
        logic [WIDTHOUT-1:0] expected;

        clk = 0;
        ena = 1;

        $display("==============================================");
        $display(" Testing MultiInputAdder ");
        $display("==============================================");


        for (i=0; i<NumTestCase; i++) begin
            din_str = "";
            for (ii=0; ii<NUMINPUT; ii++) begin
                din[ii] = $urandom_range((1<<WIDTHIN)-1);
                din_str = {din_str, $sformatf("%0d ", din[ii])};
            end

            // Wait for DUT output
            repeat (OUTDELAY) @(posedge clk);

            // Compute expected output -- UNSIGNED
            expected = ref_adder(0,din);

            // Compare
            if (dout_unsigned !== expected) begin
                $error("Mismatch! Mode=Unsigned din=[%s] dout=%0d expected=%0d",
                        din_str, dout_unsigned, expected);
                $fatal;
            end

            // Compute expected output -- SIGNED
            expected = ref_adder(1,din);

            // Compare
            if (dout_signed !== expected) begin
                $error("Mismatch! Mode=Signed din=[%s] dout=%0d expected=%0d",
                        din_str, dout_signed, expected);
                $fatal;
            end

            // Print progress every 1%
            if (i % Step == 0)
                $display("Progress: %0d%% (%s / %s)   Time=%s",
                        i/Step,
                        longint_with_commas(i),
                        longint_with_commas(NumTestCase),
                        current_sim_time($time));
        end

        $display("PASSED");
        $display("\nAll tests passed!");
        $finish;
    end




    // Current simulation time
    function automatic string current_sim_time(time t);
        int sec  = t / 1s;
        int hh   = sec / 3600;
        int mm   = (sec % 3600) / 60;
        int ss   = sec % 60;

        return $sformatf("%02d:%02d:%02d", hh, mm, ss);
    endfunction


    //Convert longint to string with commas every thousand
    function automatic string longint_with_commas (longint value);
        string s, out;
        int len, count;

        s = $sformatf("%0d", value);
        len = s.len();
        count = 0;

        for (int i = len-1; i >= 0; i--) begin
            out = {s[i], out};
            count++;

            if (count == 3 && i > 0) begin
                out = {",", out};
                count = 0;
            end
        end
        return out;
    endfunction

endmodule
