module fv_uC_8bits (
    input wire clk,
    input wire rst,
    input wire [7:0] in_gpio,         // entradas GPIO

    input wire [7:0] mem_addr,       // dirección EEPROM
    input wire mem_write_en,         // write enable externo (activo en STORE)
    input wire [7:0] mem_data,        // BUS BIDIRECCIONAL
    input wire [7:0] out_gpio        // salida GPIO
);
    `include "includes.vh"


//    `COV(wallace, sum_activa,
//        1'b1 |-> ##2,
//        Sum != 0 || Co != 0)

//    `AST(wallace, result_sum,
//        1'b1 |-> ,//##LATENCY,
//        sim_result == rtl_result);

//    `AST(wallace, sin_overflow,
//     1'b1 |-> ##2,
//     Co < (1 << WIDTH))

//    `ASM(wallace, entrada_estable,
//     1'b1 |-> ##1,
//     $stable(inputs))


endmodule


bind uC_8bits fv_uC_8bits fv_uC_8bits_i(.*);  