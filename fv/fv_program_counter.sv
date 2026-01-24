module fv_program_counter (
input  wire clk,
input  wire clk_valid,
input  wire arst_n,
input  wire pc_inc,
input  wire [ADDR_WIDTH-1:0] pc_next,  
input  wire pc_load,
input wire bootstrapping,
input reg [ADDR_WIDTH-1:0] pc_out
);
  `ifdef PROGRAM_COUNTER_TOP 
    `define PROGRAM_COUNTER_ASM 1
  `else
    `define PROGRAM_COUNTER_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind program_counter fv_program_counter fv_program_counter_i(.*);

