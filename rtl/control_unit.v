module control_unit (
    input wire clk,
    input wire arst_n,
    input wire [7:0] mem_read_data,   // viene desde mem_data_in
    input wire [7:0] alu_result,
    input wire a_greater, a_equal, carry_out,
    input wire [7:0] in_gpio,

    output reg [2:0] alu_opcode,
    output reg [7:0] alu_a,
    output reg [7:0] alu_b,
    output reg mem_write_en,
    output reg [7:0] mem_addr,
    output reg [7:0] mem_write_data,
    output reg pc_load,
    output reg [7:0] pc_next,
    output reg [7:0] out_gpio,
    output reg pc_inc         // señal para decirle al PC que avance (de 1 en 1)
);

    reg reg_write_en;
    reg [3:0] reg_write_addr;
    reg [7:0] reg_write_data;

    reg [3:0] reg_read_addr_a;
    reg [3:0] reg_read_addr_b;

    wire [7:0] reg_read_data_a;
    wire [7:0] reg_read_data_b;

    regs_16x8 regs_bank (
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

    // === FETCH MACHINE ===
    reg [7:0] instr_high;
    reg [7:0] instr_low;
    reg [15:0] instruction;
    reg [1:0] fetch_state;

    parameter FETCH_HIGH = 2'b00;
    parameter FETCH_LOW  = 2'b01;
    parameter EXECUTE    = 2'b10;

    // Flags
    reg carry_flag;
    reg greater_flag;
    reg equal_flag;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            fetch_state   <= FETCH_HIGH;
            instr_high    <= 8'b0;
            instr_low     <= 8'b0;
            instruction   <= 16'b0;
            carry_flag    <= 1'b0;
            greater_flag  <= 1'b0;
            equal_flag    <= 1'b0;
            pc_inc        <= 1'b0;
        end else begin
            pc_inc <= 1'b0;  // default

            case (fetch_state)
                FETCH_HIGH: begin
                    instr_high <= mem_read_data;
                    fetch_state <= FETCH_LOW;
                    pc_inc <= 1'b1;  // avanzar al byte bajo
                end

                FETCH_LOW: begin
                    instr_low <= mem_read_data;
                    instruction <= {instr_high, mem_read_data};
                    fetch_state <= EXECUTE;
                    pc_inc <= 1'b1;  // avanzar para próxima instrucción
                end

                EXECUTE: begin
                    execute_instruction();  // llamada a bloque combinacional
                    fetch_state <= FETCH_HIGH;
                end
					 
                default: fetch_state <= FETCH_HIGH;
            endcase

            // Actualiza flags después de ejecutar
            if (instruction[15:12] == 4'b0000)  // ADD
                carry_flag <= carry_out;
            if (instruction[15:12] == 4'b0101) begin  // CMP
                greater_flag <= a_greater;
                equal_flag   <= a_equal;
            end
        end
    end

    // === BLOQUE COMBINACIONAL PARA EJECUTAR ===
    wire [3:0] opcode, reg_dst, reg_a, reg_b;
    assign opcode  = instruction[15:12];
    assign reg_dst = instruction[11:8];
    assign reg_a   = instruction[7:4];
    assign reg_b   = instruction[3:0];

    task execute_instruction;
    begin
        // Defaults
        reg_write_en    = 1'b0;
        mem_write_en    = 1'b0;
        pc_load         = 1'b0;
        mem_addr        = 8'b0;
        mem_write_data  = 8'b0;
        out_gpio        = 8'b0;
        alu_opcode      = 3'b000;
        alu_a           = 8'b0;
        alu_b           = 8'b0;
        reg_write_addr  = reg_dst;
        reg_write_data  = 8'b0;

        if (opcode <= 4'b0111) begin
            reg_read_addr_a = reg_a;
            reg_read_addr_b = reg_b;
            alu_a           = reg_read_data_a;
            alu_b           = reg_read_data_b;
            alu_opcode      = opcode[2:0];
            reg_write_en    = 1'b1;
            reg_write_data  = alu_result;

        end else begin
            case (opcode)
                4'b1000: begin // LOAD
                    mem_addr        = {reg_a, reg_b};
                    reg_write_en    = 1'b1;
                    reg_write_data  = mem_read_data;
                end

                4'b1001: begin // STORE
                    reg_read_addr_a = reg_dst;
                    mem_addr        = {reg_a, reg_b};
                    mem_write_en    = 1'b1;
                    mem_write_data  = reg_read_data_a;
                end

                4'b1010: begin // JMP
                    pc_next = instruction[7:0];
                    pc_load = 1'b1;
                end

                4'b1011: begin // IN
                    reg_write_en    = 1'b1;
                    reg_write_data  = in_gpio;
                end

                4'b1100: begin // OUT
                    reg_read_addr_a = reg_dst;
                    out_gpio        = reg_read_data_a;
                end

                4'b1101: begin // BEQ
                    if (equal_flag) begin
                        pc_next = instruction[7:0];
                        pc_load = 1'b1;
                    end
                end

                4'b1110: begin // BGT
                    if (greater_flag) begin
                        pc_next = instruction[7:0];
                        pc_load = 1'b1;
                    end
                end

                4'b1111: begin // BC
                    if (carry_flag) begin
                        pc_next = instruction[7:0];
                        pc_load = 1'b1;
                    end
                end
            endcase
        end
    end
    endtask

endmodule
