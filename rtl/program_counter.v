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
    output reg [ADDR_WIDTH-1:0] pc_out,
	 output reg pc_valid
	 
);
	
	 assign bootstrapping = (pc_out < 12'h200); //  0x0-0x1FF Strapping Instruccions, 0x200 - 0x1FFF rest of instruccions

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            pc_out <= 12'h000; //program init
				pc_valid <= 1'b1;
        end else if (pc_load && flash_ready) begin
            pc_out <= pc_next;
				pc_valid <= 1'b1;
        end else if (pc_inc && flash_ready) begin
            pc_out <= pc_out + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
				pc_valid <= 1'b1;
		  end else
				pc_valid <= 1'b0;
    end

endmodule
