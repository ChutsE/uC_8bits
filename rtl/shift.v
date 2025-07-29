module shift #(parameter DELAY = 4)(
    input clk,
    input arst_n,
    input in,
    output out
); 
    wire [DELAY:0] wires;
    genvar i;
    generate
        for (i = 0; i < DELAY; i = i + 1) begin : FF
            flipflop ff (.clk(clk),
                         .arst_n(arst_n),
                         .in(wires[i]),
                         .out(wires[i+1]));
        end
    endgenerate

    assign wires[0]  = in;
    assign out = wires[DELAY];
endmodule
