module fv_gpio_demux (
input  wire [7:0] gpio_out,   
input  wire       sel,        
input reg  [7:0] port_a,    
input reg  [7:0] port_b      
);
  `ifdef GPIO_DEMUX_TOP 
    `define GPIO_DEMUX_ASM 1
  `else
    `define GPIO_DEMUX_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind gpio_demux fv_gpio_demux fv_gpio_demux_i(.*);

