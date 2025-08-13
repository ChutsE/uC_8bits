clear -all

analyze -sv ../rtl/flipflop.v
analyze -sv ../rtl/shift.v
analyze -sv ../rtl/bus_shift.v
analyze -sv ../rtl/alu.v
analyze -sv ../rtl/control_unit.v
analyze -sv ../rtl/sram_64x8.v
analyze -sv ../rtl/gpio_demux.v
analyze -sv ../rtl/program_counter.v
analyze -sv ../rtl/uC_8bits.v
analyze -sv ../fv/fv_uC_8bits.sv

elaborate -bbox_a 65535 -bbox_mul 65535 -top uC_8bits

clock clk

reset -expression !arst_n
set_engineJ_max_trace_length 2000
