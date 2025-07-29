module shift #(parameter DELAY = 4)(
    input clk,
    input arst_n,
    input in,
    output out
); 
    wire _wire_ [DELAY:0];
    genvar i;
    generate
        for (i = 0; i < DELAY; i = i + 1) begin
            flipflop ff (.clk(clk),
                         .arst_n(arst_n),
                         .in(_wire_[i]),
                         .out(_wire_[i+1]));
        end
    endgenerate

    assign _wire_[0]  = in;
    assign out = _wire_[DELAY];
endmodule