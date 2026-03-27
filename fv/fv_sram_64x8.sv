module fv_sram_64x8 (
input wire        clk,
input wire        clk_valid,
input wire        arst_n,
input wire        sram_write_en,
input wire [5:0]  sram_addr,
input wire [7:0]  sram_data_out,
input wire  [7:0]  sram_data_in
);
  `ifdef SRAM_64X8_TOP 
    `define SRAM_64X8_ASM 1
  `else
    `define SRAM_64X8_ASM 0
  `endif
  
  // Here add yours AST, COV, ASM, REUSE etc.
  
endmodule

bind sram_64x8 fv_sram_64x8 fv_sram_64x8_i(.*);

