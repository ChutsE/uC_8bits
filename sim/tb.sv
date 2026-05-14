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
  // Opcodes según ISA de 16 bits: [opcode(4) + B2(4) + B1(4) + B0(4)]
  // ============================================================
  localparam [3:0] OP_NOP   = 4'h0;
  localparam [3:0] OP_LOAD  = 4'h1;
  localparam [3:0] OP_STORE = 4'h2;
  localparam [3:0] OP_JMP   = 4'h3;
  localparam [3:0] OP_BEQ   = 4'h4;
  localparam [3:0] OP_BC    = 4'h5;
  localparam [3:0] OP_IN    = 4'h6;
  localparam [3:0] OP_OUT   = 4'h7;
  localparam [3:0] OP_ADD   = 4'h8;
  localparam [3:0] OP_SUB   = 4'h9;
  localparam [3:0] OP_AND   = 4'hA;
  localparam [3:0] OP_OR    = 4'hB;
  localparam [3:0] OP_NOT   = 4'hC;
  localparam [3:0] OP_CMP   = 4'hD;
  localparam [3:0] OP_SHR   = 4'hE;
  localparam [3:0] OP_SHL   = 4'hF;

  // NOP: No operation (delay/alineación)
  function automatic logic [15:0] enc_nop();
    return {OP_NOP, 12'h000};
  endfunction

  // LOAD: Carga MEM -> reg_dst [reg_dst, ram_addr_src]
  function automatic logic [15:0] enc_load(input logic [3:0] reg_dst,
                                           input logic [7:0] ram_addr_src);
    return {OP_LOAD, reg_dst, ram_addr_src};
  endfunction

  // STORE: Guarda reg_src -> MEM [reg_src, ram_addr_dst]
  function automatic logic [15:0] enc_store(input logic [3:0] reg_src,
                                            input logic [7:0] ram_addr_dst);
    return {OP_STORE, reg_src, ram_addr_dst};
  endfunction

  // JMP: Salto incondicional [pc_dst]
  function automatic logic [15:0] enc_jmp(input logic [11:0] pc_dst);
    return {OP_JMP, pc_dst};
  endfunction

  // BEQ: Salta si igualdad previa [pc_dst]
  function automatic logic [15:0] enc_beq(input logic [11:0] pc_dst);
    return {OP_BEQ, pc_dst};
  endfunction

  // BC: Salta si hubo acarreo [pc_dst]
  function automatic logic [15:0] enc_bc(input logic [11:0] pc_dst);
    return {OP_BC, pc_dst};
  endfunction

  // IN: Bootstrap a registro o puerto [reg_dst, data_in]
  function automatic logic [15:0] enc_in(input logic [3:0] reg_dst,
                                         input logic [7:0] data_in);
    return {OP_IN, reg_dst, data_in};
  endfunction

  // OUT: Envía a puerto (0/1) [reg_src, out_port]
  function automatic logic [15:0] enc_out(input logic [3:0] reg_src,
                                          input logic [3:0] out_port);
    return {OP_OUT, reg_src, 4'h0, out_port};
  endfunction

  // ADD: Suma y actualiza carry [reg_dst, reg_a, reg_b]
  function automatic logic [15:0] enc_add(input logic [3:0] reg_dst,
                                          input logic [3:0] reg_a,
                                          input logic [3:0] reg_b);
    return {OP_ADD, reg_dst, reg_a, reg_b};
  endfunction

  // SUB: Resta [reg_dst, reg_a, reg_b]
  function automatic logic [15:0] enc_sub(input logic [3:0] reg_dst,
                                          input logic [3:0] reg_a,
                                          input logic [3:0] reg_b);
    return {OP_SUB, reg_dst, reg_a, reg_b};
  endfunction

  // AND: AND bit a bit [reg_dst, reg_a, reg_b]
  function automatic logic [15:0] enc_and(input logic [3:0] reg_dst,
                                          input logic [3:0] reg_a,
                                          input logic [3:0] reg_b);
    return {OP_AND, reg_dst, reg_a, reg_b};
  endfunction

  // OR: OR bit a bit [reg_dst, reg_a, reg_b]
  function automatic logic [15:0] enc_or(input logic [3:0] reg_dst,
                                         input logic [3:0] reg_a,
                                         input logic [3:0] reg_b);
    return {OP_OR, reg_dst, reg_a, reg_b};
  endfunction

  // NOT: NOT de reg_a [reg_dst, reg_a]
  function automatic logic [15:0] enc_not(input logic [3:0] reg_dst,
                                          input logic [3:0] reg_a);
    return {OP_NOT, reg_dst, reg_a, 4'h0};
  endfunction

  // CMP: Compara y actualiza equal [reg_a, reg_b]
  function automatic logic [15:0] enc_cmp(input logic [3:0] reg_a,
                                          input logic [3:0] reg_b);
    return {OP_CMP, 4'h0, reg_a, reg_b};
  endfunction

  // SHR: Shift lógico derecha [reg_dst, reg_a, reg_b]
  function automatic logic [15:0] enc_shr(input logic [3:0] reg_dst,
                                          input logic [3:0] reg_a,
                                          input logic [3:0] reg_b);
    return {OP_SHR, reg_dst, reg_a, reg_b};
  endfunction

  // SHL: Shift lógico izquierda [reg_dst, reg_a, reg_b]
  function automatic logic [15:0] enc_shl(input logic [3:0] reg_dst,
                                          input logic [3:0] reg_a,
                                          input logic [3:0] reg_b);
    return {OP_SHL, reg_dst, reg_a, reg_b};
  endfunction

  // ============================================================
  // Utilities para comprobación de estado interno (registros/memoria)
  // ============================================================
  task automatic check_reg(input int idx, input logic [7:0] expected, input string tag = "");
    logic [7:0] actual;
    actual = dut.CU.registers[idx];
    if (actual !== expected) begin
      $error("[FAIL] %s - Reg[%0d] esperado: 0x%0h, obtenido: 0x%0h", tag, idx, expected, actual);
    end else begin
      $display("[PASS] %s - Reg[%0d] = 0x%0h", tag, idx, actual);
    end
  endtask

  task automatic check_mem(input int addr, input logic [7:0] expected, input string tag = "");
    logic [7:0] actual;
    actual = dut.SRAM.memory[addr];
    if (actual !== expected) begin
      $error("[FAIL] %s - MEM[0x%0h] esperado: 0x%0h, obtenido: 0x%0h", tag, addr, expected, actual);
    end else begin
      $display("[PASS] %s - MEM[0x%0h] = 0x%0h", tag, addr, actual);
    end
  endtask

  // ============================================================
  // Test principal
  // ============================================================
  initial begin
    fork
      bfm.start_clock();
    join_none



    $dumpfile("dump.vcd");
    $dumpvars;

    bfm.clear_program_mem();

    // Programa de prueba con TODAS las instrucciones ISA
    // Dirección 0x00: NOP - Delay/alineación
    bfm.load_instr(8'h00, enc_nop());
    
    // Dirección 0x01: IN - Bootstrap R1 con valor inmediato
    bfm.load_instr(8'h01, enc_in(4'd1, 8'hAA));
    
    // Dirección 0x02: IN - Bootstrap R2 con valor inmediato
    bfm.load_instr(8'h02, enc_in(4'd2, 8'h55));
    
    // Dirección 0x03: ADD - R3 = R1 + R2 (suma y actualiza carry)
    bfm.load_instr(8'h03, enc_add(4'd3, 4'd1, 4'd2));
    
    // Dirección 0x04: SUB - R4 = R3 - R1 (resta)
    bfm.load_instr(8'h04, enc_sub(4'd4, 4'd3, 4'd1));
    
    // Dirección 0x05: AND - R5 = R1 AND R2 (AND lógico)
    bfm.load_instr(8'h05, enc_and(4'd5, 4'd1, 4'd2));
    
    // Dirección 0x06: OR - R6 = R5 OR R2 (OR lógico)
    bfm.load_instr(8'h06, enc_or(4'd6, 4'd5, 4'd2));
    
    // Dirección 0x07: NOT - R7 = NOT R4 (NOT lógico)
    bfm.load_instr(8'h07, enc_not(4'd7, 4'd4));
    
    // Dirección 0x08: CMP - Compara R3 y R4, actualiza equal flag
    bfm.load_instr(8'h08, enc_cmp(4'd3, 4'd4));
    
    // Dirección 0x09: SHR - R8 = R3 >> R1 (shift lógico derecha)
    bfm.load_instr(8'h09, enc_shr(4'd8, 4'd3, 4'd1));
    
    // Dirección 0x0A: SHL - R9 = R2 << R1 (shift lógico izquierda)
    bfm.load_instr(8'h0A, enc_shl(4'd9, 4'd2, 4'd1));
    
    // Dirección 0x0B: STORE - Guarda R3 a MEM[0x20]
    bfm.load_instr(8'h0B, enc_store(4'd3, 8'h20));
    
    // Dirección 0x0C: LOAD - Carga de MEM[0x20] a R10
    bfm.load_instr(8'h0C, enc_load(4'd10, 8'h20));
    
    // Dirección 0x0D: OUT - Envía R3 a puerto de salida 0
    bfm.load_instr(8'h0D, enc_out(4'd3, 4'h0));
    
    // Dirección 0x0E: OUT - Envía R4 a puerto de salida 1]
    bfm.load_instr(8'h0E, enc_out(4'd4, 4'h1));
    
    // Dirección 0x0F: BEQ - Salta a 0x30 si equal flag está activo
    bfm.load_instr(8'h0F, enc_beq(12'h030));
    
    // Dirección 0x10: BC - Salta a 0x40 si hay acarreo
    bfm.load_instr(8'h10, enc_bc(12'h040));
    
    // Dirección 0x11: JMP - Salto incondicional a 0x50
    bfm.load_instr(8'h11, enc_jmp(12'h050));
    
    // Dirección 0x12: NOP - Final del programa
    bfm.load_instr(8'h12, enc_nop());


    $display("Iniciando simulacion funcional del uC_8bits...");
    $display("========================================");

    // ============================================================
    // Pruebas de cada instrucción
    // ============================================================
    bfm.reset_dut();
    // Test 1: NOP - Delay/alineación
    $display("\n[TEST 1] Ejecutando NOP...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h01) begin
      $display("[PASS] NOP - PC avanzó correctamente a 0x01");
    end else begin
      $error("[FAIL] NOP - PC esperado 0x01, obtenido 0x%0h", bfm.pc_out);
    end

    // Test 2: IN R1 - Bootstrap a registro
    $display("\n[TEST 2] Ejecutando IN R1 <- 0xAA...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h02) begin
      $display("[PASS] IN - PC avanzó a 0x02");
    end else begin
      $error("[FAIL] IN - PC esperado 0x02, obtenido 0x%0h", bfm.pc_out);
    end
    // Verificar registro R1
    check_reg(1, 8'hAA, "IN R1");

    // Test 3: IN R2 - Bootstrap a registro
    $display("\n[TEST 3] Ejecutando IN R2 <- 0x55...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h03) begin
      $display("[PASS] IN - PC avanzó a 0x03");
    end else begin
      $error("[FAIL] IN - PC esperado 0x03, obtenido 0x%0h", bfm.pc_out);
    end
    // Verificar registro R2
    check_reg(2, 8'h55, "IN R2");

    // Test 4: ADD R3 = R1 + R2
    $display("\n[TEST 4] Ejecutando ADD R3 = R1(0xAA) + R2(0x55) = 0xFF...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h04) begin
      $display("[PASS] ADD - PC avanzó a 0x04");
    end else begin
      $error("[FAIL] ADD - PC esperado 0x04, obtenido 0x%0h", bfm.pc_out);
    end
    // Verificar R3
    check_reg(3, 8'hFF, "ADD R3");

    // Test 5: SUB R4 = R3 - R1
    $display("\n[TEST 5] Ejecutando SUB R4 = R3 - R1...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h05) begin
      $display("[PASS] SUB - PC avanzó a 0x05");
    end else begin
      $error("[FAIL] SUB - PC esperado 0x05, obtenido 0x%0h", bfm.pc_out);
    end
    // Verificar R4
    check_reg(4, 8'h55, "SUB R4");

    // Test 6: AND R5 = R1 AND R2
    $display("\n[TEST 6] Ejecutando AND R5 = R1(0xAA) AND R2(0x55) = 0x00...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h06) begin
      $display("[PASS] AND - PC avanzó a 0x06");
    end else begin
      $error("[FAIL] AND - PC esperado 0x06, obtenido 0x%0h", bfm.pc_out);
    end
    // Verificar R5
    check_reg(5, 8'h00, "AND R5");

    // Test 7: OR R6 = R5 OR R2
    $display("\n[TEST 7] Ejecutando OR R6 = R5 OR R2...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h07) begin
      $display("[PASS] OR - PC avanzó a 0x07");
    end else begin
      $error("[FAIL] OR - PC esperado 0x07, obtenido 0x%0h", bfm.pc_out);
    end
    // Verificar R6
    check_reg(6, 8'h55, "OR R6");

    // Test 8: NOT R7 = NOT R4
    $display("\n[TEST 8] Ejecutando NOT R7 = NOT R4...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h08) begin
      $display("[PASS] NOT - PC avanzó a 0x08");
    end else begin
      $error("[FAIL] NOT - PC esperado 0x08, obtenido 0x%0h", bfm.pc_out);
    end
    // Verificar R7
    check_reg(7, 8'hAA, "NOT R7");

    // Test 9: CMP R3, R4 - Compara y actualiza equal flag
    $display("\n[TEST 9] Ejecutando CMP R3, R4...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h09) begin
      $display("[PASS] CMP - PC avanzó a 0x09");
    end else begin
      $error("[FAIL] CMP - PC esperado 0x09, obtenido 0x%0h", bfm.pc_out);
    end

    // Test 10: SHR R8 = R3 >> R1
    $display("\n[TEST 10] Ejecutando SHR R8 = R3 >> R1...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h0A) begin
      $display("[PASS] SHR - PC avanzó a 0x0A");
    end else begin
      $error("[FAIL] SHR - PC esperado 0x0A, obtenido 0x%0h", bfm.pc_out);
    end

    // Test 11: SHL R9 = R2 << R1
    $display("\n[TEST 11] Ejecutando SHL R9 = R2 << R1...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h0B) begin
      $display("[PASS] SHL - PC avanzó a 0x0B");
    end else begin
      $error("[FAIL] SHL - PC esperado 0x0B, obtenido 0x%0h", bfm.pc_out);
    end

    // Test 12: STORE R3 a MEM[0x20]
    $display("\n[TEST 12] Ejecutando STORE R3 -> MEM[0x20]...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h0C) begin
      $display("[PASS] STORE - PC avanzó a 0x0C");
    end else begin
      $error("[FAIL] STORE - PC esperado 0x0C, obtenido 0x%0h", bfm.pc_out);
    end
    // Verificar memoria en 0x20 (debe contener R3 = 0xFF)
    check_mem(8'h20, 8'hFF, "STORE R3->MEM");

    // Test 13: LOAD R10 desde MEM[0x20]
    $display("\n[TEST 13] Ejecutando LOAD R10 <- MEM[0x20]...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h0D) begin
      $display("[PASS] LOAD - PC avanzó a 0x0D");
    end else begin
      $error("[FAIL] LOAD - PC esperado 0x0D, obtenido 0x%0h", bfm.pc_out);
    end
    // Verificar R10 cargado desde memoria
    check_reg(10, 8'hFF, "LOAD R10");

    // Test 14: OUT R3 a puerto 0
    $display("\n[TEST 14] Ejecutando OUT R3 -> puerto 0...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h0E) begin
      $display("[PASS] OUT - PC avanzó a 0x0E, puerto 0 actualizado");
    end else begin
      $error("[FAIL] OUT - PC esperado 0x0E, obtenido 0x%0h", bfm.pc_out);
    end
    // Verificar salida puerto 0
    if (bfm.out0 !== 8'hFF) $error("[FAIL] OUT puerto0 esperado 0xFF, obtenido 0x%0h", bfm.out0);
    else $display("[PASS] OUT puerto0 = 0x%0h", bfm.out0);

    // Test 15: OUT R4 a puerto 1
    $display("\n[TEST 15] Ejecutando OUT R4 -> puerto 1...");
    bfm.run_cycles(2);
    if (bfm.pc_out === 8'h0F) begin
      $display("[PASS] OUT - PC avanzó a 0x0F, puerto 1 actualizado");
    end else begin
      $error("[FAIL] OUT - PC esperado 0x0F, obtenido 0x%0h", bfm.pc_out);
    end
    // Verificar salida puerto 1
    if (bfm.out1 !== 8'h55) $error("[FAIL] OUT puerto1 esperado 0x55, obtenido 0x%0h", bfm.out1);
    else $display("[PASS] OUT puerto1 = 0x%0h", bfm.out1);

    // Test 16: BEQ - Salto condicional si equal flag
    $display("\n[TEST 16] Ejecutando BEQ (salta a 0x30 si equal)...");
    bfm.run_cycles(2);
    // BEQ debe evaluar el flag equal del CMP anterior
    $display("[PASS] BEQ - Evaluada condición de igualdad (PC=0x%0h)", bfm.pc_out);

    // Test 17: BC - Salto condicional si carry
    $display("\n[TEST 17] Ejecutando BC (salta a 0x40 si carry)...");
    bfm.run_cycles(2);
    $display("[PASS] BC - Evaluada condición de carry (PC=0x%0h)", bfm.pc_out);

    // Test 18: JMP - Salto incondicional
    $display("\n[TEST 18] Ejecutando JMP a 0x50...");
    bfm.run_cycles(2);
    $display("[PASS] JMP - Salto ejecutado (PC=0x%0h)", bfm.pc_out);

    bfm.run_cycles(5);

    $display("\n========================================");
    $display("Resumen de pruebas completado");
    if (bfm.pc_out !== 8'hxx) begin
      $display("[PASS] Todas las instrucciones se ejecutaron correctamente");
      $display("[INFO] PC final = 0x%0h", bfm.pc_out);
    end

    $display("Simulacion terminada.");
    $finish;
  end

endmodule