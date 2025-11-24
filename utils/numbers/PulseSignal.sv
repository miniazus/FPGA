module PulseSignal #(
    parameter int DELAY = 1,
    parameter bit RZ    = 1  //Return to zero after 1 clk
)
(
    input  logic clk, ena, rst_n,
    output logic dout
);

    logic [$clog2(DELAY+2):0] count;

    generate
        always_ff @(posedge clk) begin
            if (!rst_n) begin
                count <= 0;
                dout  <= 0;
            end
            else if (ena) begin
                if (count <= DELAY)
                    count <= count + 1'b1;
                else if (RZ)
                    dout <= 1'b0;

                if (count == DELAY)
                    dout <= 1'b1;
            end
        end
    endgenerate
endmodule
