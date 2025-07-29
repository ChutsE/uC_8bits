module program_counter #(
    parameter ADDR_WIDTH = 12  // Ej: 8 bits → 256 instrucciones máximo
)(
    input  wire clk,
    input  wire arst_n,
    input wire flash_ready,
    input  wire pc_inc,           // si 1, incrementar +1
    input  wire [ADDR_WIDTH-1:0] pc_next,  // dirección para salto
    input  wire pc_load,          // si 1, cargar pc_next
    output reg [ADDR_WIDTH-1:0] pc_out    // dirección actual
);

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            pc_out <= {ADDR_WIDTH{1'b0}};
        else if (pc_load && flash_ready)
            pc_out <= pc_next;       // salto
        else if (pc_inc && flash_ready)
            pc_out <= pc_out + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};    // siguiente instrucción
    end

endmodule
