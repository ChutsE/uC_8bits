module fv_uC_8bits (
    // BlackBox
    input  logic         clk,
    input  logic         clk_valid,
    input  logic         arst_n,
    input  logic [15:0]  flash_data,
    input  logic [7:0]   in,
    input  logic [7:0]   out0, out1,
    input  logic [11:0]  pc_out,

    input  logic         bootstrapping,
    input  logic         cu_state,
    input  logic         equal_flag, carry_flag,
    input  logic         out_select,

    // WhiteBox
    input  logic         equal, carry_out,
    input  logic [7:0]   alu_result,
    input  logic [7:0]   alu_a, alu_b,
    input  logic [2:0]   alu_opcode,

    input  logic         pc_load,
    input  logic [11:0]  pc_next,
    input  logic         pc_inc
);
    `include "includes.vh"

    localparam int DELAY = 2;

    `ASM(uC_8bits, clk_valid,
        1'b1 |->, clk_valid ==  1'b1 
    )

    // =============================== ADD assert BlackBox 
    logic [8:0] add_result;
    logic [7:0] add_a, add_b;
    sequence add_sequence;
        (flash_data == {8'h61, add_a}) ##DELAY
        (flash_data == {8'h62, add_b}) ##DELAY
        (flash_data == 16'h8312);// SUM
    endsequence

    logic [7:0] add_a_reg, add_b_reg;
    bus_shift #(.DELAY(5), .WIDTH(8)) add_a_shifting (
        .clk(clk),
        .arst_n(arst_n),
        .in(add_a),
        .out(add_a_reg)
    );
    bus_shift #(.DELAY(3), .WIDTH(8)) add_b_shifting (
        .clk(clk),
        .arst_n(arst_n),
        .in(add_b),
        .out(add_b_reg)
    );

    assign add_result = add_b_reg + add_a_reg;

    property p_exec_sum_from_reset;
    @(posedge clk) disable iff (!arst_n)
        $rose(arst_n) |-> add_sequence |=> (alu_opcode==3'b000 && alu_result==add_result[7:0]);
    endproperty
    assert property (p_exec_sum_from_reset);


    // =============================== SUB assert BlackBox 
    logic [7:0] sub_a, sub_b;
    logic [8:0] sub_result;
    sequence sub_sequence;
        (flash_data == {8'h61, sub_a}) ##DELAY
        (flash_data == {8'h62, sub_b}) ##DELAY
        (flash_data == 16'h9312);// SUM
    endsequence

    logic [7:0] sub_a_reg, sub_b_reg;
    bus_shift #(.DELAY(5), .WIDTH(8)) sub_a_shifting (
        .clk(clk),
        .arst_n(arst_n),
        .in(sub_a),
        .out(sub_a_reg)
    );
    bus_shift #(.DELAY(3), .WIDTH(8)) sub_b_shifting (
        .clk(clk),
        .arst_n(arst_n),
        .in(sub_b),
        .out(sub_b_reg)
    );

    assign sub_result = sub_a_reg - sub_b_reg;

    property p_exec_sub_from_reset;
    @(posedge clk) disable iff (!arst_n)
        $rose(arst_n) |-> sub_sequence |=> (alu_opcode==3'b001 && alu_result==sub_result[7:0]);
    endproperty
    assert property (p_exec_sub_from_reset);


    // =============================== JMP assert BlackBox 
    logic [11:0] next_jump, next_jump_reg;
    bus_shift #(.DELAY(3), .WIDTH(12)) next_jump_shifting (
        .clk(clk),
        .arst_n(arst_n),
        .in(next_jump),
        .out(next_jump_reg)
    );

    property p_exec_jmp_from_reset;
    @(posedge clk) disable iff (!arst_n)
        $rose(arst_n) |-> flash_data == {4'h3, next_jump} |-> ##3 (pc_out == next_jump_reg);
    endproperty
    assert property (p_exec_jmp_from_reset);


    // =============================== BC assert BlackBox 
    logic [7:0] carry_a, carry_b;
    sequence bc_sequence;
        (flash_data == {8'h61, carry_a}) ##DELAY
        (flash_data == {8'h62, carry_b}) ##DELAY
        (flash_data == 16'h8312) ##DELAY // SUM
        (flash_data == {4'h5, next_jump}); // BC
    endsequence

    property p_exec_branch_carry_from_reset;
    @(posedge clk) disable iff (!arst_n)
        $rose(arst_n) |-> bc_sequence |-> ##3 (add_result[8] && pc_out==next_jump_reg);
    endproperty
    assert property (p_exec_branch_carry_from_reset);

    // =============================== BEQ assert BlackBox 
    logic [7:0] cmp_a, cmp_b;
    sequence beq_sequence;
        (flash_data == {8'h61, cmp_a}) ##DELAY
        (flash_data == {8'h62, cmp_b}) ##DELAY
        (flash_data == 16'hD012) ##DELAY // CMP
        (flash_data == {4'h4, next_jump}); // BEQ
    endsequence

    property p_exec_branch_equal_from_reset;
    @(posedge clk) disable iff (!arst_n)
        $rose(arst_n) |-> beq_sequence |=> (add_result[8] && pc_out==next_jump);
    endproperty
    assert property (p_exec_branch_equal_from_reset);

    // WhiteBox: suma y carry
    logic [8:0] sum;
    logic msb_sum_reg;
    assign sum = alu_a + alu_b;

    `AST(ALU, add,
        (alu_opcode == 3'b000) |->,
        (alu_result == sum[7:0] && carry_out == sum[8])
    )

    shift #(DELAY) carry_shifthing (
        .clk(clk),
        .arst_n(arst_n),
        .in(sum[8]),
        .out(msb_sum_reg)
    );

    `AST(ALU, carry_out,
        (alu_opcode == 3'b000) |-> ##DELAY,
        (carry_flag == msb_sum_reg)
    )

endmodule

bind uC_8bits fv_uC_8bits fv_uC_8bits_i(.*);
