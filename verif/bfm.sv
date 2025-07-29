
    instr_injector instr_mem (
        .clk(clk),
        .arst_n(arst_n),
        .addr(pc_out),
        .data_out(flash_data)
    );
