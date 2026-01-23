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

    wire [11:0] pc_out;
	wire [15:0] flash_data;
	 
	wire bootstrapping;
	wire cu_state;
	wire [7:0] out0, out1;
    wire equal_flag;
    wire carry_flag;
	wire out_select;
	wire clk_valid;

	assign flash_data = data_reg_a[15:0];
	assign clk_valid =  csr_in[15];

    // === Instancia del microcontrolador ===
    uC_8bits uC_inst (
        .clk(clk),
		.clk_valid(clk_valid),
        .arst_n(arst_n),
        .flash_data(flash_data),
        .in(in_gpio),

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
		15'b0, 
		equal_flag,		 // bit    16  → Equal flag
	    carry_flag,	    // bit    15  → Carry out flag
		out_select,      // bit    14  → Outport select
	    bootstrapping,   // bit    13  → boot mode bit (1:Boot, 2:Runtime)
		cu_state,        // bits   12  → CU Current state (0:FETCH, 1:EXECUTION)
		pc_out 			 // bits   11:0 → FLASH address
    };

    assign csr_out = {32'b0}; 
	assign csr_in_re = 1'b1;
	assign csr_out_we = 1'b1;


endmodule
