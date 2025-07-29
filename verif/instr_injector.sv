module instr_injector (
    input  logic clk,
    input  logic arst_n,
    input  logic [7:0] addr,
    output logic [7:0] data_out
);

    // Memoria de instrucciones ficticia
    logic [7:0] instr_mem [0:255];

    initial begin
        instr_mem[8'h00] = 8'h10; // LOAD A
        instr_mem[8'h01] = 8'h55; // Immediate 0x55
        instr_mem[8'h02] = 8'h20; // ADD B, A
        instr_mem[8'h03] = 8'h00; // NOP
        instr_mem[8'h04] = 8'h30; // STORE A
        instr_mem[8'h05] = 8'h20; // Dirección 0x20
        instr_mem[8'h06] = 8'h00; // NOP
    end

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            data_out <= 8'h00;
        else
            data_out <= instr_mem[addr];
    end
endmodule
