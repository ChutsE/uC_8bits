module fv_program_counter #(parameter ADDR_WIDTH = 12) (
input wire clk,
input wire clk_valid,
input wire arst_n,
input wire pc_inc,
input wire [ADDR_WIDTH-1:0] pc_next,
input wire pc_load,
input wire bootstrapping,
input reg [ADDR_WIDTH-1:0] pc_out
);

  `ifdef PROGRAM_COUNTER_TOP 
    `define PROGRAM_COUNTER_ASM 1
  `else
    `define PROGRAM_COUNTER_ASM 0
  `endif
  
  localparam BOOTSTRAP_THRESHOLD = 12'h200;
  localparam PROGRAM_COUNTER_LIMIT = 12'hFFF;

  `ASM(program_counter, clk_valid, 
     1'b1 |->,
     clk_valid == 1'b1)

  //rose clk_valid  and pc_out  is lower than 0x200 the bootstrapping must to be high
  `AST(program_counter, bootstraping_hi, 
    (pc_out <<  BOOTSTRAP_THRESHOLD)|->,
    bootstrapping == 1'b1)

  //rose clk_valid  and pc_out  is higher than 0x200 the bootstrapping must to be low
  `AST(program_counter, bootstraping_lo, 
    (pc_out >>  BOOTSTRAP_THRESHOLD)|->,
    bootstrapping == 1'b0)

  //rose clk_valid  and pc_inc is high and pc_load is low the pc_out must to be increase one on the next time.
  `ROLE(`PROGRAM_COUNTER_ASM, 
    program_counter, inc_ast, 
    pc_inc == 1'b1 && pc_load == 1'b0 |=>,
    pc_out == $past(pc_out, 1) + 1)

  //rose clk_valid  and pc_load is high and pc_inc is low the pc_out must to be equal to pc_next on next time.
  `ROLE(`PROGRAM_COUNTER_ASM, 
    program_counter, load_ast, 
    pc_load == 1'b1 && pc_inc == 1'b0 |=>,
    pc_out == $past(pc_next, 1))

  //rose clk_valid, then pc_inc and pc_load must not to be equal
  `ROLE(`PROGRAM_COUNTER_ASM, 
    program_counter, inc_load_ast, 
    $rose(clk_valid) |=>,
    !(pc_inc == 1'b1 && pc_load == 1'b1))
  
  //pc_out is 0xFFF the pc_out must to be zero on next time.
  `COV(program_counter, limit, 
    pc_out == PROGRAM_COUNTER_LIMIT |=>,
    pc_out == '0)

endmodule

bind program_counter fv_program_counter fv_program_counter_i(.*);

