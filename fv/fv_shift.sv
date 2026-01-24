module fv_shift #(parameter DELAY = 4) (
input clk,
input arst_n,
input in,
input out
);
  `ifdef SHIFT_TOP 
    `define SHIFT_ASM 1
  `else
    `define SHIFT_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind shift fv_shift fv_shift_i(.*);

