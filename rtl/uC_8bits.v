module uC_8bits (
    input wire        clk,
	 input wire        clk_valid,
    input wire        arst_n,
    input wire [7:0]  in,
    input wire [15:0] flash_data,

    output wire [7:0]  out0, out1,
    output wire [11:0] pc_out,

    // === Debug Signals ===
    output wire        bootstrapping,
    output wire        cu_state,
    output wire        equal_flag, carry_flag,
	 output wire        out_select
);
    wire        sram_write_en;
    wire [5:0]  sram_addr;
    wire [7:0]  sram_data_out;
	 wire [7:0]  sram_data_in;
    // === Señales internas ===
    wire [7:0]  alu_a, alu_b;
    wire [2:0]  alu_opcode;
    wire        equal, carry_out;
    wire [11:0] pc_next;
	 wire [7:0]  out_gpio;
	 wire [7:0]  alu_result;
	 wire        pc_load;
	 wire        pc_inc;
	 

	 // === Output demux ===
	 gpio_demux DEMUX (
        .gpio_out(out_gpio),   
        .sel(out_select),        
        .port_a(out0),    
        .port_b(out1)    
	 );
	 
    // === Program counter ===
    program_counter #(.ADDR_WIDTH(12)) PC (
        .clk(clk),
		  .clk_valid(clk_valid),
        .arst_n(arst_n),
        .pc_inc(pc_inc),
        .pc_next(pc_next),
        .pc_load(pc_load),
        .pc_out(pc_out),
        .bootstrapping(bootstrapping)
    );

    // === ALU ===
    alu ALU (
        .a(alu_a),
        .b(alu_b),
        .opcode(alu_opcode),
        .result(alu_result),
        .equal_out(equal),
        .carry_out(carry_out)
    );

    // === flags register ===
    bus_shift #(.DELAY(2), .WIDTH(2)) FLAGS (
        .clk(clk_valid),
        .arst_n(arst_n),
        .in({equal, carry_out}),
        .out({equal_flag, carry_flag})
    );

    // === Control Unit ===
    control_unit CU (
        .clk(clk),
		  .clk_valid(clk_valid),
        .arst_n(arst_n),
        .instruction(flash_data),
        .sram_read_data(sram_data_in),
        .alu_result(alu_result),
        .equal(equal_flag),
        .carry_out(carry_flag),
        .in_gpio(in),
        .bootstrapping(bootstrapping),
        .alu_opcode(alu_opcode),
        .alu_a(alu_a),
        .alu_b(alu_b),
        .sram_write_en(sram_write_en),
        .sram_addr(sram_addr),   
        .sram_write_data(sram_data_out),    
        .pc_load(pc_load),
        .pc_next(pc_next),
        .pc_inc(pc_inc),                 
        .out_gpio(out_gpio),
		  .out_port(out_select),
        .state(cu_state)
    );

	sram_64x8 SRAM (
		.clk(clk),
		.clk_valid(clk_valid),
		.arst_n(arst_n),
		.sram_write_en(sram_write_en),
		.sram_addr(sram_addr),
		.sram_data_out(sram_data_out),
		.sram_data_in(sram_data_in)
	);


endmodule
