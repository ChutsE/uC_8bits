module fv_control_unit (
input wire clk,
input wire clk_valid,
input wire arst_n,
input wire [15:0] instruction,
input wire [7:0] sram_read_data,
input wire [7:0] alu_result,
input wire equal, carry_out,
input wire [7:0] in_gpio,
input wire bootstrapping,
input reg [2:0] alu_opcode,
input reg [7:0] alu_a,
input reg [7:0] alu_b,
input reg sram_write_en,
input reg [5:0] sram_addr,
input reg [7:0] sram_write_data,
input reg pc_load,
input reg [11:0] pc_next,
input reg [7:0] out_gpio,
input wire pc_inc,
input reg state,
input reg out_port
);
  `ifdef CONTROL_UNIT_TOP 
    `define CONTROL_UNIT_ASM 1
  `else
    `define CONTROL_UNIT_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind control_unit fv_control_unit fv_control_unit_i(.*);

