clear -all

set_proofgrid_bridge off

set fv_analyze_options { -sv12 }
set design_top shifting_cell

if {[info exists PROGRAM_COUNTER_TOP]} {
  lappend fv_analyze +define+PROGRAM_COUNTER_TOP
  set design_top program_counter
}

if {[info exists UC_8BITS_TOP]} {
  lappend fv_analyze +define+UC_8BITS_TOP
  set design_top uc_8bits
}

if {[info exists ALU_TOP]} {
  lappend fv_analyze +define+ALU_TOP
  set design_top alu
}

if {[info exists GPIO_DEMUX_TOP]} {
  lappend fv_analyze +define+GPIO_DEMUX_TOP
  set design_top gpio_demux
}

if {[info exists BUS_SHIFT_TOP]} {
  lappend fv_analyze +define+BUS_SHIFT_TOP
  set design_top bus_shift
}

if {[info exists CONTROL_UNIT_TOP]} {
  lappend fv_analyze +define+CONTROL_UNIT_TOP
  set design_top control_unit
}

if {[info exists SRAM_64X8_TOP]} {
  lappend fv_analyze +define+SRAM_64X8_TOP
  set design_top sram_64x8
}

analyze [join $fv_analyze_options] -f analyze.flist

elaborate -bbox_a 65535 -bbox_mul 65535 -non_constant_loop_limit 2000 -top $design_top
get_design_info

clock clk
reset -expression !arst_n
set_engineJ_max_trace_length 2000

prove -all

