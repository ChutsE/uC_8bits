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
  
  wire [3:0] instr_opcode, reg_dst, reg_1, reg_2;  

  assign instr_opcode = flash_data[15:12];
  assign reg_dst = flash_data[11:8];
  assign reg_1 = flash_data[7:4];
  assign reg_2 = flash_data[3:0];

  `ASM(uc, clk_valid, 
    1'b1 |->,
    clk_valid == 1'b1)

  //when instr_opcode is equal to LOAD and state is equal to STATE_FETCH,  
  //memory[{reg_2, reg_1}] must to be equal to registers[reg_dst] on the next time.
  `AST(uc, load, 
    instr_opcode == LOAD  && (cu_state == STATE_FETCH) |-> ##DELAY,
    uc_8bits.sram_64x8.memory[{reg_1, reg_2}] == $past(uc_8bits.control_unit.registers[reg_dst], DELAY))

  //when instr_opcode is equal to STORE and state is equal to STATE_FETCH, 
  //registers[reg_dst] must to be equal to  memory[{reg_2, reg_1}] on the next time.
  `AST(uc, store, 
    instr_opcode == STORE && (cu_state == STATE_FETCH) |-> ##DELAY,
    uc_8bits.control_unit.registers[reg_dst] == $past(uc_8bits.sram_64x8.memory[{reg_1, reg_2}], DELAY))

  
endmodule

bind uc_8bits fv_uc_8bits fv_uc_8bits_i(.*);

