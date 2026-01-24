module fv_flipflop (
input wire clk,
input wire arst_n,
input wire in,
input reg out
);
  `ifdef FLIPFLOP_TOP 
    `define FLIPFLOP_ASM 1
  `else
    `define FLIPFLOP_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind flipflop fv_flipflop fv_flipflop_i(.*);

