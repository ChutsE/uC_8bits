module fv_bus_shift #(parameter DELAY=4, WIDTH=10) (
input clk,
input arst_n,
input [WIDTH-1:0] in,
input [WIDTH-1:0] out
);
  `ifdef BUS_SHIFT_TOP 
    `define BUS_SHIFT_ASM 1
  `else
    `define BUS_SHIFT_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind bus_shift fv_bus_shift fv_bus_shift_i(.*);

