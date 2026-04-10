module fv_sram_64x8 (
//Blackbox Signals
input wire        clk,
input wire        clk_valid,
input wire        arst_n,
input wire        sram_write_en,
input wire [5:0]  sram_addr,
input wire [7:0]  sram_data_out,
input wire  [7:0]  sram_data_in,

//Whitebox Signals
input reg [7:0] memory [0:63]
);
  `ifdef SRAM_64X8_TOP 
    `define SRAM_64X8_ASM 1
  `else
    `define SRAM_64X8_ASM 0
  `endif

  //clk_valid must to be 1'b1 always
  `ROLE( `SRAM_64X8_ASM,
    sram_64x8, clk_valid, 
    1'b1 |->,
    clk_valid == 1'b1)

  //sram_write_en low, sram_data_in must to be the same to memory[sram_addr] on the next time
  `AST(sram_64x8, read_ast, 
    sram_write_en == 1'b0 |=>,
    sram_data_in == $past(memory[sram_addr]))

  //sram_write_en high, memory[sram_addr]  must to be the same to sram_data_out on the next time
  `AST(sram_64x8, write_ast, 
    sram_write_en == 1'b1 |=>,
    memory[$past(sram_addr)] == $past(sram_data_out))

endmodule

bind sram_64x8 fv_sram_64x8 fv_sram_64x8_i(.*);

