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

  localparam PORT0 = 1'b0;
  localparam PORT1 = 1'b1;
  localparam STATE_FETCH = 1'b0;
  localparam STATE_EXECUTE = 1'b1;

  //clk_valid must to be 1'b1 always
  `ROLE(`CONTROL_UNIT_ASM,
    control_unit, clk_valid, 
    1'b1 |->,
    clk_valid == 1'b1)

  //when instr_opcode is equal to NOP and state is equal to STATE_FETCH, 
  //all output signals must to keep the values.
  `AST(control_unit, nop, 
    instr_opcode == NOP && (state == STATE_FETCH) |=> ,
    {sram_write_en, pc_load, pc_next, out_gpio, out_port} ==  \
    $past({sram_write_en, pc_load, pc_next, out_gpio, out_port}))

  //when instr_opcode is equal to JMP and state is equal to STATE_FETCH, 
  //pc_next must to be equal to {reg_dst, reg_2, reg_1} on the next time.
  `AST(control_unit, jmp, 
     (instr_opcode == JMP) && (state == STATE_FETCH) |-> ##DELAY,
    pc_next == $past({reg_dst, reg_1, reg_2}, DELAY))


  //when instr_opcode is equal to BEQ, state is equal to STATE_FETCH and equal is high, 
  //pc_next must to be equal to {reg_dst, reg_2, reg_1} on the next time.
  `AST(control_unit, beq, 
     (instr_opcode == BEQ)  && (state == STATE_FETCH) && (equal == 1'b1) |-> ##DELAY,
    pc_next == $past({reg_dst, reg_1, reg_2}, DELAY))


  //when instr_opcode is equal to BC, state is equal to STATE_FETCH and carry_out is high,
  //pc_next must to be equal to {reg_dst, reg_2, reg_1} on the next time.
  `AST(control_unit, bc, 
     (instr_opcode == BC) && (state == STATE_FETCH) && (carry_out == 1'b1) |-> ##DELAY,
    pc_next == $past({reg_dst, reg_1, reg_2}, DELAY))


  //when instr_opcode is equal to IN, state is equal to STATE_FETCH  and pc_next <= BOOTSTRAP_THRESHOLD,
  // in_gpio   must to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, in_bootstrapping, 
     (instr_opcode == IN) && (state == STATE_FETCH) |=> (bootstrapping == 1'b1) |=>,
    registers[$past(reg_dst, DELAY)] == $past({reg_1, reg_2}, DELAY))


  //when instr_opcode is equal to IN, state is equal to STATE_FETCH  and pc_next > BOOTSTRAP_THRESHOLD, 
  //{reg_2, reg_1} must to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, in, 
     (instr_opcode == IN) && (state == STATE_FETCH) |=> (bootstrapping == 1'b0) |=>,
    registers[$past(reg_dst, DELAY)] == $past(in_gpio, DELAY))
    
  
  //when instr_opcode is equal to OUT and state is equal to STATE_FETCH and reg_2 is equal to PORT0,  
  //registers[reg_dst] must to be equal to out_gpio and out_port equal to PORT0 on the next time.
  `AST(control_unit, out_port0, 
     (instr_opcode == OUT) && (state == STATE_FETCH) && (reg_2 == PORT0)|-> ##DELAY,
    out_gpio == $past(registers[reg_dst], DELAY) && out_port == PORT0)


  //when instr_opcode is equal to OUT, state is equal to STATE_FETCH and reg_2 is equal to PORT1, 
  //registers[reg_dst] must to be equal to out_gpio and out_port equal to PORT1 on the next time.
  `AST(control_unit, out_port1, 
     (instr_opcode == OUT) && (state == STATE_FETCH) && (reg_2 == PORT1)|-> ##DELAY,
    out_gpio == $past(registers[reg_dst], DELAY) && out_port == PORT1)


  //when instr_opcode is equal to ADD and state is equal to STATE_FETCH , 
  //registers[reg_1] +  registers[reg_2] must  to be equal to {carry_out,  registers[reg_dst]}on the next time.
  logic [8:0] add;
  assign add = registers[reg_1] + registers[reg_2];
  `AST(control_unit, add, 
     (instr_opcode == ADD) && (state == STATE_FETCH) |-> ##DELAY,
    {carry_out, registers[$past(reg_dst, DELAY)]} == $past(add, DELAY))
    
  
  //when instr_opcode equal to SUB and state is equal to STATE_FETCH,  
  //registers[reg_1] -  registers[reg_2] must  to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, sub, 
     (instr_opcode == SUB) && (state == STATE_FETCH) |-> ##DELAY,
    registers[$past(reg_dst, DELAY)] == $past(registers[reg_1] - registers[reg_2], DELAY))


  //when instr_opcode equal to AND and state is equal to STATE_FETCH, 
  //registers[reg_1] &  registers[reg_2] must  to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, and, 
     (instr_opcode == AND) && (state == STATE_FETCH) |-> ##DELAY,
    registers[$past(reg_dst, DELAY)] == $past(registers[reg_1] & registers[reg_2], DELAY))


  //when instr_opcode equal to OR and state is equal to STATE_FETCH,  
  //registers[reg_1] |  registers[reg_2] must  to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, or, 
     (instr_opcode == OR) && (state == STATE_FETCH) |-> ##DELAY,
    registers[$past(reg_dst, DELAY)] == $past(registers[reg_1] | registers[reg_2], DELAY))


  //when instr_opcode equal to NOT and state is equal to STATE_FETCH ,  
  //~registers[reg_1]  must  to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, not, 
     (instr_opcode == NOT) && (state == STATE_FETCH) |-> ##DELAY,
    registers[$past(reg_dst, DELAY)] == $past(~registers[reg_1], DELAY))
  

  //when instr_opcode equal to CMP and state is equal to STATE_FETCH ,  
  //if registers[reg_1] is equal to registers[reg_2],  equal signal will rise on the next time.
  `AST(control_unit, cmp_equal, 
     (instr_opcode == CMP) && (state == STATE_FETCH) && (registers[reg_1] == registers[reg_2]) |-> ##DELAY,
    equal == 1'b1)


  //when instr_opcode equal to RSHT and state is equal to STATE_FETCH,  
  //registers[reg_1] >>  reg_2 must  to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, lsht, 
     (instr_opcode == LSHT) && (state == STATE_FETCH) |-> ##DELAY,
    registers[$past(reg_dst, DELAY)] == $past(registers[reg_1] << registers[reg_2], DELAY))


  //when instr_opcode equal to LSHT and state is equal to STATE_FETCH,
  //registers[reg_1] <<  reg_2 must  to be equal to registers[reg_dst] on the next time.
  `AST(control_unit, rsht, 
     (instr_opcode == RSHT) && (state == STATE_FETCH) |-> ##DELAY,
    registers[$past(reg_dst, DELAY)] == $past(registers[reg_1] >> registers[reg_2], DELAY))
  
endmodule

bind control_unit fv_control_unit fv_control_unit_i(.*);

