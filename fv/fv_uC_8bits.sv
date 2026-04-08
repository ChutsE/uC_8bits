module fv_uc_8bits (
input wire        clk,
input wire        clk_valid,
input wire        arst_n,
input wire [7:0]  in,
input wire [15:0] flash_data,
input wire [7:0]  out0, out1,
input wire [11:0] pc_out,
input wire        bootstrapping,
input wire        cu_state,
input wire        equal_flag, carry_flag,
input wire        out_select
);
  `ifdef UC_8BITS_TOP 
    `define UC_8BITS_ASM 1
  `else
    `define UC_8BITS_ASM 0
  `endif
  
  `ASM(uc_8bits, clk_valid, 
    1'b1 |->,
    clk_valid == 1'b1)
  
endmodule

bind uc_8bits fv_uc_8bits fv_uc_8bits_i(.*);

