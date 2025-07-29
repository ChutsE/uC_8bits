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