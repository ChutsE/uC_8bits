module regs_16x8 (
   input wire clk,
   input wire arst_n,

   // Escritura
   input wire reg_write_en,
   input wire [3:0] reg_write_addr, 
   input wire [7:0] reg_write_data,
   // Lectura
   input wire [3:0] reg_read_addr_a,
	input wire [3:0] reg_read_addr_b,
	 
	output wire [7:0] reg_read_data_a,
	output wire [7:0] reg_read_data_b
);

	reg [7:0] registers [0:15];
	
	assign reg_read_data_a = registers[reg_read_addr_a];
	assign reg_read_data_b = registers[reg_read_addr_b];
	
	always @(posedge clk or negedge arst_n) begin
		 if (!arst_n) begin
			  integer i;
			  for (i = 0; i < 16; i = i + 1)
					registers[i] <= 8'h00;
		 end else if (reg_write_en) begin
			  registers[reg_write_addr] <= reg_write_data;
		 end
	end

endmodule
