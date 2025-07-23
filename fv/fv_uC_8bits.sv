module fv_uC_8bits (
    input wire clk,
    input wire arst_n,
    input wire [7:0] in_gpio,
    input wire [7:0] mem_addr,
    input wire mem_write_en,
    input wire [7:0] mem_data,
    input wire [7:0] out_gpio
);
    `include "includes.vh"

`AST(uC, gpio_stable,
    1'b1 |-> ##1,
    !$isunknown(out_gpio))

`AST(uC, mem_data_never_x,
    mem_write_en == 0 |-> ##1,
    !$isunknown(mem_data))

`AST(uC, no_write_without_enable,
    mem_write_en == 0 |-> ##1,
    $stable(mem_data))

`AST(uC, add_instr,
    mem_write_en == 1  |-> ##1)


endmodule

bind uC_8bits fv_uC_8bits fv_uC_8bits_i(.*);
