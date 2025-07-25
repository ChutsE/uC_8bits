clear -all

analyze -verilog ../rtl/regs_16x8.v
analyze -verilog ../rtl/control_unit.v
analyze -verilog ../rtl/program_counter.v
analyze -verilog ../rtl/alu.v
analyze -verilog ../rtl/uC_8bits.v
analyze -sv ../fv/fv_uC_8bits.sv

elaborate -bbox_a 65535 -bbox_mul 65535 -top uC_8bits

clock clk

reset -expression !arst_n
set_engineJ_max_trace_length 2000
