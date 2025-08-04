module tile_wrapper_esparza_jesus#(parameter OWNER_NAME_LENGTH = 20, REG_WIDTH = 32, CSR_IN_WIDTH = 16, CSR_OUT_WIDTH = 16, GPIOS_NUM = 35) (
  `ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
  `endif
  input clk,
  input arst_n,
  input harness_en,
  input tile_en,
  input [CSR_IN_WIDTH - 1 : 0] csr_in,
  output wire csr_in_re,
  input [REG_WIDTH - 1 : 0] data_reg_a,
  input [REG_WIDTH - 1 : 0] data_reg_b,
  output wire [CSR_OUT_WIDTH - 1 : 0] csr_out,
  output wire csr_out_we,
  output wire [REG_WIDTH - 1 : 0] data_reg_c,
  output wire [OWNER_NAME_LENGTH*8 - 1 : 0] owner_name,
  input wire [GPIOS_NUM - 1 : 0] gpios_in, // you can either use this or gpios_out, i.e. if you are using gpios_in[0] you can not use gpios_out[0], or any other index
  output wire [GPIOS_NUM - 1 : 0] gpios_out // you can either use this or gpios_in, i.e. if you are using gpios_out[0] you can not use gpios_in[0], or any other index
);
  parameter [OWNER_NAME_LENGTH*8 - 1 : 0] param_owner_name = "Esparza-Jesus";
  assign owner_name = param_owner_name;

  wire [CSR_IN_WIDTH - 1 : 0] csr_in_w;
  wire [REG_WIDTH - 1 : 0] data_reg_a_w;
  wire [REG_WIDTH - 1 : 0] data_reg_b_w;
  wire [15:0] out;
  wire [7:0] in;
  
  assign in = gpios_in[7:0];
  
  assign gpios_out = {
		19'b0,
		out
  };
  

  masking_logic #(CSR_IN_WIDTH, CSR_OUT_WIDTH, REG_WIDTH, GPIOS_NUM) masking_logic_i(
    .clk(clk),
    .arst_n(arst_n),
    .harness_en(harness_en),
    .tile_en(tile_en),
    .icsr_in(csr_in),
    .idata_reg_a(data_reg_a),
    .idata_reg_b(data_reg_b),
    .ocsr_in(csr_in_w),
    .odata_reg_a(data_reg_a_w),
    .odata_reg_b(data_reg_b_w),
	.gpios_in(gpios_in),
	.ogpios_in(gpios_in_w)
  );

  // TODO: here goes the user tile logic instantiation
  ip_tile_uC #(REG_WIDTH, CSR_IN_WIDTH, CSR_OUT_WIDTH) ip_tile_i(
    .clk(clk),
    .arst_n(arst_n),
    .csr_in(csr_in_w),
    .csr_in_re(csr_in_re),
    .data_reg_a(data_reg_a_w),
    .data_reg_b(data_reg_b_w),
    .csr_out(csr_out),
    .csr_out_we(csr_out_we),
    .data_reg_c(data_reg_c),
	 .in_gpio(in),
	 .out_gpio(out)
  );

endmodule
