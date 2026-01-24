module fv_adder #(parameter WIDTH = 8) (
input wire [WIDTH-1:0] a, b,
input wire [WIDTH-1:0] sum,
input wire co
);
  `ifdef ADDER_TOP 
    `define ADDER_ASM 1
  `else
    `define ADDER_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind adder fv_adder fv_adder_i(.*);

module fv_subtractor #(parameter WIDTH = 8) (
input wire [WIDTH-1:0] a, b,
input wire [WIDTH-1:0] diff
);
  `ifdef SUBTRACTOR_TOP 
    `define SUBTRACTOR_ASM 1
  `else
    `define SUBTRACTOR_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind subtractor fv_subtractor fv_subtractor_i(.*);

module fv_bitwise_and #(parameter WIDTH = 8) (
input wire [WIDTH-1:0] a, b,
input wire [WIDTH-1:0] b_and
);
  `ifdef BITWISE_AND_TOP 
    `define BITWISE_AND_ASM 1
  `else
    `define BITWISE_AND_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind bitwise_and fv_bitwise_and fv_bitwise_and_i(.*);

module fv_bitwise_or #(parameter WIDTH = 8) (
input wire [WIDTH-1:0] a, b,
input wire [WIDTH-1:0] b_or
);
  `ifdef BITWISE_OR_TOP 
    `define BITWISE_OR_ASM 1
  `else
    `define BITWISE_OR_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind bitwise_or fv_bitwise_or fv_bitwise_or_i(.*);

module fv_bitwise_not #(parameter WIDTH = 8) (
input wire [WIDTH-1:0] a,
input wire [WIDTH-1:0] a_not
);
  `ifdef BITWISE_NOT_TOP 
    `define BITWISE_NOT_ASM 1
  `else
    `define BITWISE_NOT_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind bitwise_not fv_bitwise_not fv_bitwise_not_i(.*);

module fv_comparator #(parameter WIDTH = 8) (
input wire [WIDTH-1:0] a, b,
input wire equal
);
  `ifdef COMPARATOR_TOP 
    `define COMPARATOR_ASM 1
  `else
    `define COMPARATOR_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind comparator fv_comparator fv_comparator_i(.*);

module fv_left_shift #(parameter WIDTH = 8) (
input wire [WIDTH-1:0] a,
input wire [WIDTH-1:0] shift,
input wire [WIDTH-1:0] left_shift
);
  `ifdef LEFT_SHIFT_TOP 
    `define LEFT_SHIFT_ASM 1
  `else
    `define LEFT_SHIFT_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind left_shift fv_left_shift fv_left_shift_i(.*);

module fv_right_shift #(parameter WIDTH = 8) (
input wire [WIDTH-1:0] a,
input wire [WIDTH-1:0] shift,
input wire [WIDTH-1:0] right_shift
);
  `ifdef RIGHT_SHIFT_TOP 
    `define RIGHT_SHIFT_ASM 1
  `else
    `define RIGHT_SHIFT_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind right_shift fv_right_shift fv_right_shift_i(.*);

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

