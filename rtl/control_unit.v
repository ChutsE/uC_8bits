module control_unit (
    input wire clk,
    input wire arst_n,
    input wire [15:0] instruction,
    input wire [7:0] sram_read_data,
    input wire [7:0] alu_result,
    input wire equal, carry_out,
    input wire [7:0] in_gpio,
    input wire bootstrapping,

    output reg [2:0] alu_opcode,
    output reg [7:0] alu_a,
    output reg [7:0] alu_b,
    output reg sram_write_en,
    output reg [7:0] sram_addr,
    output reg [7:0] sram_write_data,
    output reg pc_load,
    output reg [11:0] pc_next,
    output reg [7:0] out_gpio,
    output wire pc_inc,
    output reg [1:0] state,
	 output reg out_port
);

    // === Estados ===
    parameter FETCH   = 1'b0;
    parameter EXECUTE = 1'b1;

    assign pc_inc = (state == FETCH);

    // === Campos de instrucción ===
    reg [3:0] opcode, reg_dst, reg_a, reg_b;

    // === Banco de registros interno ===
    reg [7:0] registers [0:15];
    integer i;


    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            state <= FETCH;
            out_gpio <= 8'b0;
            pc_load <= 1'b0;
            sram_write_en <= 1'b0;
            sram_write_data <= 8'b0;

            for (i = 0; i < 16; i = i + 1)
                registers[i] <= 8'h00;

        end else begin
            case (state)
                FETCH: begin
						 opcode  <= instruction[15:12];
						 reg_dst <= instruction[11:8];
						 reg_a   <= instruction[7:4];
						 reg_b   <= instruction[3:0];
						 alu_a      <= registers[instruction[7:4]];
						 alu_b      <= registers[instruction[3:0]];
						 alu_opcode <= instruction[14:12];
                   state   <= EXECUTE;
                end

                EXECUTE: begin
                    // Defaults
                    pc_load         <= 1'b0;
                    sram_write_en   <= 1'b0;
                    sram_write_data <= 8'b0;
                    sram_addr       <= {reg_a, reg_b};
                    //out_gpio        <= 8'b0;

                    case (opcode)
                        4'b0000: ; // NOP

                        4'b0001: begin // LOAD
                            registers[reg_dst] <= sram_read_data;
                        end

                        4'b0010: begin // STORE
                            sram_write_en   <= 1'b1;
                            sram_write_data <= registers[reg_dst];
                        end

                        4'b0011: begin // JMP
                            pc_next <= {reg_dst, reg_a, reg_b};
                            pc_load <= 1'b1;
                        end

                        4'b0100: begin // BEQ
                            if (equal) begin
                                pc_next <= {reg_dst, reg_a, reg_b};
                                pc_load <= 1'b1;
                            end
                        end

                        4'b0101: begin // BC
                            if (carry_out) begin
                                pc_next <= {reg_dst, reg_a, reg_b};
                                pc_load <= 1'b1;
                            end
                        end

                        4'b0110: begin // IN
                            registers[reg_dst] <= bootstrapping ? {reg_a, reg_b} : in_gpio;
                        end

                        4'b0111: begin // OUT
                            out_gpio <= registers[reg_dst];
									 out_port <= reg_b[0];
                        end

                        default: begin // ALU
                            registers[reg_dst] <= alu_result;
                        end
                    endcase

                    state <= FETCH;
                end
            endcase
        end
    end

endmodule
