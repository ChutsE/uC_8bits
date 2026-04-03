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

  //rose clk_valid  and  sram_write_en low, sram_data_in must to be the same to memory[sram_addr] on the next time
  `ROLE(`SRAM_64X8_ASM, 
    sram_64x8, read_ast, 
    $rose(clk_valid) && sram_write_en == 1'b0 |=>,
    sram_data_in == $past(memory[sram_addr], 1))

  //rose clk_valid  and  sram_write_en high,   sram_data_out must to be the same to memory[sram_addr] on the next time
  `ROLE(`SRAM_64X8_ASM, 
    sram_64x8, write_ast, 
    $rose(clk_valid) && sram_write_en == 1'b1 |=>,
    sram_data_out == $past(memory[sram_addr], 1))

endmodule

bind sram_64x8 fv_sram_64x8 fv_sram_64x8_i(.*);

