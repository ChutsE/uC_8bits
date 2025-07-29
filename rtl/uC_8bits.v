module uC_8bits (
    input wire       clk,
    input wire       arst_n,
    input wire [7:0] flash_data,
    input wire       flash_ready,
    input wire [7:0] in_gpio,
    input wire [7:0] sram_data_in,

    output wire [7:0]  sram_addr,       
    output wire        sram_write_en,         
    output wire [7:0]  sram_data_out,
    output wire [7:0]  out_gpio,
    output wire [11:0] pc_out
);

    // === Señales internas ===
    wire [7:0] alu_result;
    wire a_greater, a_equal, carry_out;
    wire a_greater_reg, a_equal_reg, carry_out_reg;
    wire [7:0] alu_a, alu_b;
    wire [3:0] alu_opcode;

    wire pc_load;
    wire [11:0] pc_next;
    wire pc_inc;

    wire reg_write_en;
    wire [3:0] reg_write_addr;
    wire [7:0] reg_write_data;
    wire [3:0] reg_read_addr_a;
    wire [3:0] reg_read_addr_b;
    wire [7:0] reg_read_data_a;
    wire [7:0] reg_read_data_b;

    // === Registers  ===
    regs_16x8 REGS (
        .clk(clk),
        .arst_n(arst_n),
        .reg_write_en(reg_write_en),
        .reg_write_addr(reg_write_addr),
        .reg_write_data(reg_write_data),
        .reg_read_addr_a(reg_read_addr_a),
        .reg_read_addr_b(reg_read_addr_b),
        .reg_read_data_a(reg_read_data_a),
        .reg_read_data_b(reg_read_data_b)
    );

    // === Program counter ===
    program_counter #(.ADDR_WIDTH(12)) PC (
        .clk(clk),
        .arst_n(arst_n),
        .flash_ready(),
        .pc_inc(pc_inc),
        .pc_next(pc_next),
        .pc_load(pc_load),
        .pc_out(pc_out)
    );

    // === ALU ===
    alu ALU (
        .a(alu_a),
        .b(alu_b),
        .opcode(alu_opcode),
        .result(alu_result),
        .a_greater_out(a_greater),
        .a_equal_out(a_equal),
        .carry_out(carry_out)
    );

    // === flags register ===
    bus_shift #(.DELAY(3), .WIDTH(3)) FLAGS (
        .clk(clk),
        .arst_n(arst_n),
        .in({a_greater, a_equal, carry_out}),
        .out({a_greater_reg, a_equal_reg, carry_out_reg})
    );

    // === Control Unit ===
    control_unit CU (
        .clk(clk),
        .arst_n(arst_n),
		.flash_data(flash_data),
        .sram_read_data(sram_data_in),
        .alu_result(alu_result),
        .a_greater(a_greater_reg),
        .a_equal(a_equal_reg),
        .carry_out(carry_out_reg),
        .in_gpio(in_gpio),
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
        .reg_write_en(reg_write_en),
        .reg_write_addr(reg_write_addr),
        .reg_write_data(reg_write_data),
        .reg_read_addr_a(reg_read_addr_a),
        .reg_read_addr_b(reg_read_addr_b),
        .reg_read_data_a(reg_read_data_a),
        .reg_read_data_b(reg_read_data_b)
    );

endmodule
