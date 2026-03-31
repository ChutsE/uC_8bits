module fv_alu #(parameter WIDTH = 8, parameter OPCODE_WIDTH = 3) (
input wire [WIDTH-1:0] a, b,
input wire [OPCODE_WIDTH-1:0] opcode,
input wire [WIDTH-1:0] result,
input wire equal_out, carry_out
);
  `ifdef ALU_TOP 
    `define ALU_ASM 1
  `else
    `define ALU_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind alu fv_alu fv_alu_i(.*);