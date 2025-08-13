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

    `ASM(uC_8bits, clk_valid,
        1'b1 |->, clk_valid ==  1'b1 
    )

    localparam int DELAY = 2;

    logic [8:0] add_result;
    logic [7:0] add_a, add_b;
    sequence add_sequence;
        
        (flash_data == {8'h61, add_a}) ##DELAY
        (flash_data == {8'h62, add_b}) ##DELAY
        (flash_data == 16'h8312);// SUM
    endsequence

    logic [7:0] add_a_reg, add_b_reg;
    bus_shift #(.DELAY(5), .WIDTH(8)) a_shifting (
        .clk(clk),
        .arst_n(arst_n),
        .in(add_a),
        .out(add_a_reg)
    );
    bus_shift #(.DELAY(3), .WIDTH(8)) b_shifting (
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

    // WhiteBox: suma y carry
    logic [8:0] sum;
    assign sum = alu_a + alu_b;

    `AST(ALU, add,
        (alu_opcode == 3'b000) |->,
        (alu_result == sum[7:0] && carry_out == sum[8])
    )

    `AST(ALU, carry_out,
        (alu_opcode == 3'b000) |-> ##DELAY,
        (carry_flag == sum[8])
    )

endmodule

bind uC_8bits fv_uC_8bits fv_uC_8bits_i(.*);
