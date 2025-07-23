module uC_8bits (
    input wire clk,
    input wire arst_n,
    input wire [7:0] in_gpio,         // entradas GPIO

    output wire [7:0] mem_addr,       // dirección EEPROM
    output wire mem_write_en,         // write enable externo (activo en STORE)
    inout wire [7:0] mem_data,        // BUS BIDIRECCIONAL
    output wire [7:0] out_gpio        // salida GPIO
);

    // === Señales internas ===
    wire [7:0] alu_result;
    wire a_greater, a_equal, carry_out;

    wire [7:0] alu_a, alu_b;
    wire [2:0] alu_opcode;

    wire pc_load;
    wire [7:0] pc_next;
    wire [7:0] pc_out;

    wire [7:0] mem_data_out;        // datos que salen del uC a memoria
    wire [7:0] mem_data_in;         // datos que vienen de memoria
    wire [7:0] mem_addr_from_cu;
    wire pc_inc;                    // señal nueva para incremento del PC (de a 1)

    assign mem_data = (mem_write_en) ? mem_data_out : 8'bZ;  // manejar bus bidireccional
    assign mem_data_in = mem_data;                           // siempre leer

    // === MUX de dirección ===
    assign mem_addr = (mem_write_en) ? mem_addr_from_cu : pc_out;

    // === Program counter ===
    program_counter #(.ADDR_WIDTH(8)) PC (
        .clk(clk),
        .arst_n(arst_n),
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
        .arst_n(arst_n),
        .mem_read_data(mem_data_in),       // lectura desde memoria externa
        .alu_result(alu_result),
        .a_greater(a_greater),
        .a_equal(a_equal),
        .carry_out(carry_out),
        .in_gpio(in_gpio),
        .alu_opcode(alu_opcode),
        .alu_a(alu_a),
        .alu_b(alu_b),
        .mem_write_en(mem_write_en),
        .mem_addr(mem_addr_from_cu),      // dirección para LOAD/STORE
        .mem_write_data(mem_data_out),    // datos a escribir
        .pc_load(pc_load),
        .pc_next(pc_next),
        .pc_inc(pc_inc),                  // ← nueva señal de avance +1 por ciclo
        .out_gpio(out_gpio)
    );

endmodule
