module uC_8bits (
    input wire        clk,
    input wire        arst_n,
    input wire [15:0] flash_data,
    input wire        flash_ready,
    input wire [7:0]  in_gpio,
    input wire [7:0]  sram_data_in,

    output wire [7:0]  sram_addr,       
    output wire        sram_write_en,         
    output wire [7:0]  sram_data_out,
    output wire [7:0]  out0, out1,
    output wire [11:0] pc_out,

    // === Debug Signals ===
    output wire        bootstrapping,
    output wire        cu_state,
    output wire        pc_inc,
    output wire        pc_load,
    output wire        equal_reg,
    output wire        carry_out_reg,
    output wire [7:0]  alu_result
);

    // === Señales internas ===
    wire [7:0]  alu_a, alu_b;
    wire [2:0]  alu_opcode;
    wire        equal, carry_out;
    wire [11:0] pc_next;
	 wire        out_port;
	 wire [7:0]  out_gpio;

	 // === Output demux ===
	 gpio_demux DEMUX (
        .gpio_out(out_gpio),   
        .sel(out_port),        
        .port_a(out0),    
        .port_b(out1)    
	 );
	 
    // === Program counter ===
    program_counter #(.ADDR_WIDTH(12)) PC (
        .clk(clk),
        .arst_n(arst_n),
        .flash_ready(flash_ready),
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
        .clk(clk),
        .arst_n(arst_n),
        .in({equal, carry_out}),
        .out({equal_reg, carry_out_reg})
    );

    // === Control Unit ===
    control_unit CU (
        .clk(clk),
        .arst_n(arst_n),
        .instruction(flash_data),
        .sram_read_data(sram_data_in),
        .alu_result(alu_result),
        .equal(equal_reg),
        .carry_out(carry_out_reg),
        .in_gpio(in_gpio),
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
		  .out_port(out_port),
        .state(cu_state)
    );


endmodule
