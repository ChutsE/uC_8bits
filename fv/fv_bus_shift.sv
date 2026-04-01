module fv_bus_shift #(parameter DELAY=2, WIDTH=2) (
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
  
  //the in must not be unknown
  `ROLE(`BUS_SHIFT_ASM,
    bus_shift, in_known_ast,
    1'b1 |->,
    !$isunknown(in))
  
  //the in must to be the same of out on the second next time . 
  `ROLE(`BUS_SHIFT_ASM,
    bus_shift, shift_ast,
    1'b1 |-> ##DELAY,
    out == $past(in, DELAY))

endmodule

bind bus_shift fv_bus_shift fv_bus_shift_i(.*);

