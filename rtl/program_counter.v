module program_counter #(
    parameter ADDR_WIDTH = 12  
)(
    input  wire clk,
    input  wire arst_n,
    input  wire flash_ready,
    input  wire pc_inc,
    input  wire [ADDR_WIDTH-1:0] pc_next,  
    input  wire pc_load,
	 output wire bootstrapping,
    output reg [ADDR_WIDTH-1:0] pc_out
	 
);
	
	 assign bootstrapping = (pc_out < 12'h100) ? 1'b1:1'b0; // 0-0x7F Straps, 0x80-0x27F Strapping Instruccions, 0x280 - 0x1FFF rest of instruccions

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            pc_out <= 12'h080; //program init
        else if (pc_load && flash_ready)
            pc_out <= pc_next;
        else if (pc_inc && flash_ready)
            pc_out <= pc_out + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
    end

endmodule
