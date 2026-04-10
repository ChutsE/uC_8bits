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

  localparam DELAY = 2;
  localparam LOAD = 4'b0001;
  localparam STORE = 4'b0010;
  localparam STATE_FETCH = 1'b0;
  
  wire [3:0] instr_opcode, reg_idx;  
  wire [5:0] sram_idx;
  assign instr_opcode = flash_data[15:12];
  assign reg_idx = flash_data[11:8];
  assign sram_idx = flash_data[5:0];

  `ASM(uc, clk_valid, 
    1'b1 |->,
    clk_valid == 1'b1)

  //when instr_opcode is equal to LOAD and state is equal to STATE_FETCH, 
  //registers[reg_idx] must to be equal to  memory[{reg_2, reg_1}] on the next time.
  `AST(uc, load, 
    instr_opcode == LOAD && (cu_state == STATE_FETCH) |-> ##DELAY,
    uc_8bits.CU.registers[$past(reg_idx, DELAY)] == $past(uc_8bits.SRAM.memory[sram_idx], DELAY))

  //when instr_opcode is equal to STORE and state is equal to STATE_FETCH,  
  //memory[{reg_2, reg_1}] must to be equal to registers[reg_idx] on the next time.
  `AST(uc, store, 
    instr_opcode == STORE  && (cu_state == STATE_FETCH) |-> ##DELAY,
    uc_8bits.SRAM.memory[$past(sram_idx, DELAY)] == $past(uc_8bits.CU.registers[reg_idx], DELAY))



  
endmodule

bind uc_8bits fv_uc_8bits fv_uc_8bits_i(.*);

