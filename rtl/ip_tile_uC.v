module ip_tile_uC #(
    parameter REG_WIDTH = 32,
    parameter CSR_IN_WIDTH = 16,
    parameter CSR_OUT_WIDTH = 16
)(
    input  wire clk,
    input  wire arst_n,
    input  wire [CSR_IN_WIDTH-1:0] csr_in,
    input  wire [REG_WIDTH-1:0] data_reg_a,
    input  wire [REG_WIDTH-1:0] data_reg_b,
	 input  wire [7:0] in_gpio,
	 
    output wire [REG_WIDTH-1:0] data_reg_c,
    output wire [CSR_OUT_WIDTH-1:0] csr_out,
	 output wire [15:0] out_gpio,
    output wire csr_in_re,
    output wire csr_out_we
);

    // === Señales internas ===
    wire [7:0] sram_addr;
    wire [7:0] sram_data_out;
    wire [11:0] pc_out;
	 
	 wire [15:0] flash_data;
	 wire [7:0] sram_data_in;
	 wire sram_write_en;
	 wire flash_ready;
	 
	 wire bootstrapping;
	 wire [1:0] cu_state;
	 wire [7:0] out0, out1;
    wire equal_flag;
    wire carry_flag;
	 wire out_select;
	 
	 assign sram_data_in = data_reg_a[7:0];
	 assign flash_data = data_reg_b[15:0];
	 assign flash_ready = csr_in[4];

    // === Instancia del microcontrolador ===
    uC_8bits uC_inst (
        .clk(clk),
        .arst_n(arst_n),
        .flash_data(flash_data),
		  .flash_ready(flash_ready),
        .in(in_gpio),
        .sram_data_in(sram_data_in),

        .sram_addr(sram_addr),
        .sram_write_en(sram_write_en),
        .sram_data_out(sram_data_out),
        .out0(out0),
		  .out1(out1),
        .pc_out(pc_out),
			
			// Debug signals
		  .bootstrapping(bootstrapping),
		  .cu_state(cu_state),
		  .equal_flag(equal_flag),
		  .carry_flag(carry_flag),
		  .out_select(out_select)
    );

	 assign out_gpio = {
		  out1,             // Port 0 OUT
		  out0              // Port 1 OUT
	 };
	 
    assign data_reg_c = {
        3'b0,             // bits 31:29 → ceros
		  pc_out,			  // bits 28:17 → FLASH address
		  sram_write_en,    // bit  16    → SRAM write enable
        sram_data_out,    // bits 15:8  → SRAM data out
        sram_addr         // bits 7:0   → SRAM address
    };

    assign csr_out = {
		  7'b0,            // bits 15:9 → ceros
	     bootstrapping,   // bit    8  → boot mode bit (1:Boot, 2:Runtime)
	     cu_state,        // bits   7  → CU Current state (0:FETCH, 1:EXECUTION)
		  equal_flag,		 // bit    6  → Equal flag
	     carry_flag,	    // bit    5  → Carry out flag
		  out_select,      // bit    4  → SRAM write enable
		  4'b0             // bits 3:0  → ceros
	 };
	 
	 assign csr_in_re = 1'b1;
	 assign csr_out_we = 1'b1;


endmodule
