`timescale 1ns/1ps

module tb_MultiInputAdderWithRounding;

    // Parameters for the test
    parameter NUM_INPUT   = 4;
    parameter WIDTH_IN    = 8;
    parameter WIDTH_OUT   = 8;
    parameter IS_SIGNED   = 1;  // change to 0 to test unsigned
    parameter IS_FRACTION = 0;  // change to 1 to test fractional rounding

    // Clock and enable
    logic clk;
    logic ena;

    // Input and output
    logic signed [WIDTH_IN-1:0] din [NUM_INPUT];
    logic signed [WIDTH_OUT-1:0] dout;

    // Instantiate the DUT
    MultiInputAdderWithRounding #(
        .NUM_INPUT(NUM_INPUT),
        .WIDTH_IN(WIDTH_IN),
        .WIDTH_OUT(WIDTH_OUT),
        .IS_SIGNED(IS_SIGNED),
        .IS_FRACTION(IS_FRACTION)
    ) dut (
        .clk(clk),
        .ena(ena),
        .din(din),
        .dout(dout)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz clock

    // Test procedure
    initial begin
        ena = 1;

        // Test case 1: simple positive numbers
        din[0] = 8'd10;
        din[1] = 8'd20;
        din[2] = 8'd30;
        din[3] = 8'd40;
        #10;
        $display("Test 1: Sum = %0d", dout);

        // Test case 2: including negative numbers if signed
        if (IS_SIGNED) begin
            din[0] = -8'd50;
            din[1] = 8'd30;
            din[2] = -8'd20;
            din[3] = 8'd10;
            #10;
            $display("Test 2: Sum = %0d", dout);
        end

        // Test case 3: max values to test rounding/saturation
        din[0] = 8'sd127;
        din[1] = 8'sd127;
        din[2] = 8'sd127;
        din[3] = 8'sd127;
        #10;
        $display("Test 3: Sum = %0d", dout);

        // Test case 4: fractional rounding example (if IS_FRACTION)
        if (IS_FRACTION) begin
            din[0] = 8'sd25;  // 0.25
            din[1] = 8'sd50;  // 0.50
            din[2] = 8'sd75;  // 0.75
            din[3] = 8'sd100; // 1.00
            #10;
            $display("Test 4: Sum (fraction) = %0d", dout);
        end

        $finish;
    end

endmodule
