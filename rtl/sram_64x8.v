module sram_64x8 (
    input  wire        clk,
	 input  wire        clk_valid,
    input  wire        arst_n,
    input  wire        sram_write_en,     
    input  wire [5:0]  sram_addr,
    input  wire [7:0]  sram_data_out,
    output wire  [7:0]  sram_data_in 
);

    reg [7:0] memory [0:63];
	 assign sram_data_in = memory[sram_addr];
	 integer i;
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            for (i = 0; i < 64; i = i + 1)
                memory[i] <= 8'b0;
        end else begin
            if(clk_valid && sram_write_en) memory[sram_addr] <= sram_data_out;
        end
    end
endmodule
