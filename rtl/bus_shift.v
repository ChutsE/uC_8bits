module bus_shift #(parameter DELAY=4, WIDTH=10)(
    input clk,
    input arst_n,
    input [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            shift #(DELAY) shift_inst (
                .clk(clk),
                .arst_n(rst),
                .in(in[i]),
                .out(out[i])
            );
        end
    endgenerate
endmodule