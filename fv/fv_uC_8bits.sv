module fv_uC_8bits (
    //BlackBox
    input logic clk,
    input logic clk_valid,
    input logic arst_n,
	input logic [15:0] flash_data,
    input logic [7:0] in,

    input logic [7:0] out0, out1,     
	input logic [11:0] pc_out,

    input logic bootstrapping,
    input logic cu_state,
    input logic equal_flag, carry_flag,
	input logic out_select,

    //WhiteBox
    input logic [7:0] alu_result,
    input logic [7:0] alu_a, alu_b,
    input logic [2:0] alu_opcode,

    input logic pc_load,
    input logic [7:0] pc_next,
    input logic pc_inc              
    
);
    `include "includes.vh"
    
    `ASM(uC_8bits, clk_valid,
        1'b1 |->, clk_valid == 1'b1
    )
    localparam DELAY = 2;
    instr_injector instr_mem (
        .clk(clk),
        .arst_n(arst_n),
        .addr(pc_out),
        .data_out(flash_data)
    );
    assign ca
    sequence fetch_sequence;
        flash_data == 16'h60FF ##DELAY 
        flash_data == 16'h61FF ##DELAY
        flash_data == 16'h8210 ##DELAY //SUM
        flash_data == 16'h5000;
    endsequence

    //BlackBox
    `AST(CU, exec_sum,
        fetch_sequence |-> ##1,
        (alu_opcode == 3'b000 && alu_result == 8'h55))

    //WhiteBox
    logic [8:0] sum;
    assign sum = alu_a + alu_b;

    `AST(ALU, add,
        alu_opcode == 3'b000 |->,
        alu_result == sum[7:0] and carry_flag == sum[8])
    

endmodule

bind uC_8bits fv_uC_8bits fv_uC_8bits_i(.*);
