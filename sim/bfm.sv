interface uc8_bfm_if #(parameter ADDR_WIDTH = 8,
                       parameter DATA_WIDTH = 8,
                       parameter INST_WIDTH = 16);

  logic clk;
  logic clk_valid;
  logic arst_n;
  logic [DATA_WIDTH-1:0] in_gpio;

  // Bus de instruccion de 16 bits hacia el DUT
  logic [INST_WIDTH-1:0] flash_data;

  // Salidas del DUT
  logic [DATA_WIDTH-1:0] out0;
  logic [DATA_WIDTH-1:0] out1;
  logic [11:0] pc_out;

  // Opcional: señales observables del DUT
  logic bootstrapping;
  logic cu_state;
  logic equal_flag;
  logic carry_flag;
  logic out_select;

  // Memoria modelo
  logic [7:0] program_mem [0:255];

  // Clock
  task automatic start_clock();
    clk = 0;
    forever #5 clk = ~clk;
  endtask

  // Reset
  task automatic reset_dut();
    arst_n = 0;
    clk_valid = 1'b1;
    in_gpio = '0;
    repeat (5) @(posedge clk);
    arst_n = 1;
    repeat (2) @(posedge clk);
  endtask

  // Cargar instrucción de 16 bits en memoria de 8 bits
  task automatic load_instr(input int addr, input logic [15:0] instr);
    program_mem[addr]     = instr[15:8]; // byte alto
    program_mem[addr + 1] = instr[7:0];  // byte bajo
  endtask

  // Limpiar memoria
  task automatic clear_program_mem();
    for (int i = 0; i < 256; i++) begin
      program_mem[i] = 8'h00;
    end
  endtask

  // Ejecutar N ciclos
  task automatic run_cycles(input int n);
    repeat (n) @(posedge clk);
  endtask

  // Verificar PC
  task automatic check_pc(input logic [11:0] expected);
    if (pc_out !== expected) begin
      $error("[PC CHECK] Esperado: 0x%0h, obtenido: 0x%0h", expected, pc_out);
    end else begin
      $display("[PASS] PC = 0x%0h", pc_out);
    end
  endtask

endinterface