module fv_control_unit (
//Blackbox Signals
input wire clk,
input wire clk_valid,
input wire arst_n,
input wire [15:0] instruction,
input wire [7:0] sram_read_data,
input wire [7:0] alu_result,
input wire equal, carry_out,
input wire [7:0] in_gpio,
input wire bootstrapping,
input reg [2:0] alu_opcode,
input reg [7:0] alu_a,
input reg [7:0] alu_b,
input reg sram_write_en,
input reg [5:0] sram_addr,
input reg [7:0] sram_write_data,
input reg pc_load,
input reg [11:0] pc_next,
input reg [7:0] out_gpio,
input wire pc_inc,
input reg state,
input reg out_port,

//Whitebox Signals
input reg [7:0] registers [0:15]
);
  `ifdef CONTROL_UNIT_TOP 
    `define CONTROL_UNIT_ASM 1
  `else
    `define CONTROL_UNIT_ASM 0
  `endif

  wire [3:0] instr_opcode, reg_dst, reg_1, reg_2;  

  assign instr_opcode = instruction[15:12];
  assign reg_dst = instruction[11:8];
  assign reg_1 = instruction[7:4];
  assign reg_2 = instruction[3:0];

  localparam BOOTSTRAP_THRESHOLD = 12'h200;
  localparam DELAY = 2;

  localparam NOP = 4'b0000;
  localparam LOAD = 4'b0001;
  localparam STORE = 4'b0010;
  localparam JMP = 4'b0011;
  localparam BEQ = 4'b0100;
  localparam BC = 4'b0101;
  localparam IN = 4'b0110;
  localparam OUT = 4'b0111;
  localparam ADD = 4'b1000;
  localparam SUB = 4'b1001;
  localparam AND = 4'b1010;
  localparam OR = 4'b1011;
  localparam NOT = 4'b1100;
  localparam CMP = 4'b1101;
  localparam LSHT = 4'b1110;
  localparam RSHT = 4'b1111;


  `ASM(program_counter, clk_valid, 
     1'b1 |->,
     clk_valid == 1'b1)

  //rose clk_valid and instr_opcode equal to NOP, all output signals must to keep the values.
  `AST(control_unit, nop_ast, 
    instr_opcode == NOP |=>,
    {alu_opcode, alu_a, alu_b, sram_write_en, sram_addr, sram_write_data, pc_load, pc_next, out_gpio, state} == $past({alu_opcode, alu_a, alu_b, sram_write_en, sram_addr, sram_write_data, pc_load, pc_next, out_gpio, state}, 1))

  //rose clk_valid and instr_opcode equal to LOAD,  memory[{reg_2, reg_1}] must to be equal to   registers[reg_dst] on the next time.
  //AST(control_unit, load_ast, 
  //   instr_opcode == LOAD |=>,
  //  memory[{reg_2, reg_1}] == $past(registers[reg_dst], 1))

  //rose clk_valid and instr_opcode equal to STORE,   registers[reg_dst] must to be equal to  memory[{reg_2, reg_1}] on the next time.
  //`AST(control_unit, store_ast, 
  //   instr_opcode == STORE |=>,
  //  registers[reg_dst] == $past(memory[{reg_2, reg_1}], 1))

  //rose clk_valid and instr_opcode equal to JMP,   pc_next must to be equal to {reg_dst, reg_2, reg_1} on the next time.
  `AST(control_unit, jmp_ast, 
     instr_opcode == JMP |-> ##DELAY,
    pc_next == $past({reg_dst, reg_2, reg_1}, DELAY))

  //rose clk_valid and instr_opcode equal to BEQ and equal is high,   pc_next must to be equal to {reg_dst, reg_2, reg_1} on the next time.
  `AST(control_unit, beq_ast, 
     instr_opcode == BEQ && equal == 1'b1 |->##DELAY,
    pc_next == $past({reg_dst, reg_2, reg_1}, DELAY))

  //rose clk_valid and instr_opcode equal to BC and carry_out is high,  pc_next must to be equal to {reg_dst, reg_2, reg_1} on the next time.
  `AST(control_unit, bc_ast, 
     instr_opcode == BC && carry_out == 1'b1 |->##DELAY,
    pc_next == $past({reg_dst, reg_2, reg_1}, DELAY))

  //rose clk_valid and instr_opcode equal to IN and pc_next <= BOOTSTRAP_THRESHOLD , in_gpio   must to be equal to [reg_dst] on the next time.
  `AST(control_unit, in_bootstrapping_ast, 
     instr_opcode == IN && pc_next <= BOOTSTRAP_THRESHOLD |->##DELAY,
    in_gpio == $past(registers[reg_dst], DELAY))

  //rose clk_valid and instr_opcode equal to IN and pc_next > BOOTSTRAP_THRESHOLD , {reg_2, reg_1} must to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, in_ast, 
     instr_opcode == IN && pc_next > BOOTSTRAP_THRESHOLD |->##DELAY,
    {reg_2, reg_1} == $past(registers[reg_dst], DELAY))
    
  //rose clk_valid and instr_opcode equal to OUT,  registers[reg_dst] must to be equal to out_gpio on the next time.
  `AST(control_unit, out_ast, 
     instr_opcode == OUT |->##DELAY,
    registers[reg_dst] == $past(out_gpio, DELAY))

  //rose clk_valid and instr_opcode equal to ADD, registers[reg_1] +  registers[reg_2] must  to be equal to {carry_out,  registers[reg_dst]}on the next time.
  `AST(control_unit, add_ast, 
     instr_opcode == ADD |->##DELAY,
    {carry_out, registers[reg_dst]} == $past({reg_1, reg_2}, DELAY))
    
  //rose clk_valid and instr_opcode equal to SUB,  registers[reg_1] -  registers[reg_2] must  to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, sub_ast, 
     instr_opcode == SUB |->##DELAY,
    registers[reg_dst] == $past(registers[reg_1] - registers[reg_2], DELAY))

  //rose clk_valid and instr_opcode equal to OR,   registers[reg_1] |  registers[reg_2] must  to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, or_ast, 
     instr_opcode == OR |->##DELAY,
    registers[reg_dst] == $past(registers[reg_1] | registers[reg_2], DELAY))

  //rose clk_valid and instr_opcode equal to NOT,  ~registers[reg_1] must  to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, not_ast, 
     instr_opcode == NOT |->##DELAY,
    registers[reg_dst] == $past(~registers[reg_1], DELAY))
  
  //rose clk_valid and instr_opcode equal to CMP,  if registers[reg_1] is equal to registers[reg_2],  equal signal will rise on the next time.
  `AST(control_unit, cmp_equal_ast, 
     instr_opcode == CMP && registers[reg_1] == registers[reg_2] |->,
    equal == 1'b1)

  //rose clk_valid and instr_opcode equal to LSHT,  registers[reg_1] <<  reg_2 must  to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, lsht_ast, 
     instr_opcode == LSHT |->##DELAY,
    registers[reg_dst] == $past(registers[reg_1] << registers[reg_2], DELAY))

  //rose clk_valid and instr_opcode equal to RSHT,  registers[reg_1] >>  reg_2 must  to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, rsht_ast, 
     instr_opcode == RSHT |->##DELAY,
    registers[reg_dst] == $past(registers[reg_1] >> registers[reg_2], DELAY))
  
endmodule

bind control_unit fv_control_unit fv_control_unit_i(.*);

