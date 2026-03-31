module flipflop (
    input wire clk,
    input wire arst_n,
    input wire in,
    output reg out
);

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) out <= 1'b0;
        else         out <= in;
    end

endmodule


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


module bus_shift #(parameter DELAY=4, WIDTH=10)(
    input clk,
    input arst_n,
    input [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : SHIFT
            shift #(DELAY) shift_inst ( .clk(clk),
                                        .arst_n(arst_n),
                                        .in(in[i]),
                                        .out(out[i]));
        end
    endgenerate
endmodule