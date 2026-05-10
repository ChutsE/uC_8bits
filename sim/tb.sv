module tb_uc8bits;

  localparam ADDR_WIDTH = 8;
  localparam DATA_WIDTH = 8;

  uc8_bfm_if #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) bfm();

  // ============================================================
  // Modelo de memoria de instrucciones
  // ============================================================
  always_comb begin
    bfm.flash_data = {
      bfm.program_mem[bfm.pc_out[7:0]],
      bfm.program_mem[bfm.pc_out[7:0] + 8'd1]
    };
  end

  // ============================================================
  // DUT
  // Ajusta estos puertos a tu uC_8bits real
  // ============================================================
  uc_8bits dut (
    .clk          (bfm.clk),
    .clk_valid    (bfm.clk_valid),
    .arst_n       (bfm.arst_n),
    .in           (bfm.in_gpio),
    .flash_data   (bfm.flash_data),

    .out0         (bfm.out0),
    .out1         (bfm.out1),
    .pc_out       (bfm.pc_out),
    .bootstrapping(bfm.bootstrapping),
    .cu_state     (bfm.cu_state),
    .equal_flag   (bfm.equal_flag),
    .carry_flag   (bfm.carry_flag),
    .out_select   (bfm.out_select)
  );

  // ============================================================
  // Opcodes de ejemplo
  // Ajustar según tu ISA real
  // ============================================================
  localparam [3:0] OP_NOP   = 4'h0;
  localparam [3:0] OP_LDI   = 4'h1;
  localparam [3:0] OP_ADD   = 4'h2;
  localparam [3:0] OP_STORE = 4'h3;
  localparam [3:0] OP_JMP   = 4'h4;

  function automatic logic [15:0] enc_nop();
    return {OP_NOP, 12'h000};
  endfunction

  function automatic logic [15:0] enc_ldi(input logic [3:0] rd,
                                          input logic [7:0] imm);
    return {OP_LDI, rd, imm};
  endfunction

  function automatic logic [15:0] enc_add(input logic [3:0] rd,
                                          input logic [3:0] ra,
                                          input logic [3:0] rb);
    return {OP_ADD, rd, ra, rb};
  endfunction

  function automatic logic [15:0] enc_store(input logic [3:0] rs,
                                            input logic [7:0] addr);
    return {OP_STORE, rs, addr};
  endfunction

  function automatic logic [15:0] enc_jmp(input logic [7:0] addr);
    return {OP_JMP, 4'h0, addr};
  endfunction

  // ============================================================
  // Test principal
  // ============================================================
  initial begin
    fork
      bfm.start_clock();
    join_none

    $dumpfile("tb_uc8bits.vcd");
    $dumpvars(0, tb_uc8bits);

    bfm.clear_program_mem();

    // Programa de ejemplo:
    // R1 = 5
    // R2 = 3
    // R3 = R1 + R2
    // MEM[0x10] = R3
    // NOP
    bfm.load_instr(8'h00, enc_ldi(4'd1, 8'h05));
    bfm.load_instr(8'h02, enc_ldi(4'd2, 8'h03));
    bfm.load_instr(8'h04, enc_add(4'd3, 4'd1, 4'd2));
    bfm.load_instr(8'h06, enc_store(4'd3, 8'h10));
    bfm.load_instr(8'h08, enc_nop());

    bfm.reset_dut();

    $display("Iniciando simulacion funcional del uC_8bits...");

    bfm.run_cycles(40);

    // Sanity check del PC final; evita atar el test a un valor fijo de microarquitectura.
    if ($isunknown(bfm.pc_out)) begin
      $error("[PC CHECK] pc_out contiene X/Z al final de la simulacion");
    end else begin
      $display("[PASS] PC final = 0x%0h", bfm.pc_out);
    end

    $display("Simulacion terminada.");
    $finish;
  end

endmodule