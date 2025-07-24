module uC_8bits (
    input wire clk,
    input wire rst,
    input wire [7:0] flash_data,
    input wire [7:0] in_gpio,         // entradas GPIO

    output wire [7:0] sram_addr,       // dirección EEPROM
    output wire sram_write_en,         // write enable externo (activo en STORE)
    inout wire [7:0] sram_data,        // BUS BIDIRECCIONAL
    output wire [7:0] out_gpio,      // salida GPIO
	 output wire [11:0] pc_out
);

    // === Señales internas ===
    wire [7:0] alu_result;
    wire a_greater, a_equal, carry_out;

    wire [7:0] alu_a, alu_b;
    wire [3:0] alu_opcode;

    wire pc_load;
    wire [11:0] pc_next;

    wire [7:0] sram_data_out;        // datos que salen del uC a memoria
    wire [7:0] sram_data_in;         // datos que vienen de memoria
    wire pc_inc;                    // señal nueva para incremento del PC (de a 1)

    assign sram_data = (sram_write_en) ? sram_data_out : sram_data_in;  // manejar bus bidireccional


    // === Program counter ===
    program_counter #(.ADDR_WIDTH(12)) PC (
        .clk(clk),
        .rst(rst),
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

    // === Control Unit (con máquina de estados fetch-execute) ===
    control_unit CU (
        .clk(clk),
        .rst(rst),
		  .flash_data(flash_data),
        .sram_read_data(sram_data_in),       // lectura desde memoria externa
        .alu_result(alu_result),
        .a_greater(a_greater),
        .a_equal(a_equal),
        .carry_out(carry_out),
        .in_gpio(in_gpio),
        .alu_opcode(alu_opcode),
        .alu_a(alu_a),
        .alu_b(alu_b),
        .sram_write_en(sram_write_en),
        .sram_addr(sram_addr),      // dirección para LOAD/STORE
        .sram_write_data(sram_data_out),    // datos a escribir
        .pc_load(pc_load),
        .pc_next(pc_next),
        .pc_inc(pc_inc),                  // ← nueva señal de avance +1 por ciclo
        .out_gpio(out_gpio)
    );

endmodule
