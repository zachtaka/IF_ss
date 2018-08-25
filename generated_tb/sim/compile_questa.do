
file delete -force work

vlib work

vlog -sv ../tb/IF/sv/util_pkg.sv
vlog -sv ../tb/IF/sv/drivers/drivers_pkg.sv

#compile the dut code
set cmd "vlog -F ../dut/files.f +cover"
eval $cmd

set tb_name top
set agent_list {\ 
    IF \
}
foreach  ele $agent_list {
  if {$ele != " "} {
    set cmd  "vlog -sv +incdir+../tb/include +incdir+../tb/"
    append cmd $ele "/sv ../tb/" $ele "/sv/" $ele "_pkg.sv ../tb/" $ele "/sv/" $ele "_if.sv"
    eval $cmd
  }
}

set cmd  "vlog -sv +incdir+../tb/include +incdir+../tb/"
append cmd $tb_name "/sv ../tb/" $tb_name "/sv/" $tb_name "_pkg.sv"
eval $cmd

set cmd  "vlog -sv +incdir+../tb/include +incdir+../tb/"
append cmd $tb_name "_test/sv ../tb/" $tb_name "_test/sv/" $tb_name "_test_pkg.sv"
eval $cmd

set cmd  "vlog -sv -timescale 1ns/1ps +incdir+../tb/include +incdir+../tb/"
append cmd $tb_name "_tb/sv ../tb/" $tb_name "_tb/sv/" $tb_name "_th.sv"
eval $cmd

set cmd  "vlog -sv -timescale 1ns/1ps +incdir+../tb/include +incdir+../tb/"
append cmd $tb_name "_tb/sv ../tb/" $tb_name "_tb/sv/" $tb_name "_tb.sv"
eval $cmd

vsim top_tb -novopt +UVM_TESTNAME=top_test  -voptargs=+acc -solvefaildebug -uvmcontrol=all -classdebug -onfinish "stop" -assertcover -coverage +cover=bcfst
run 0
log -r /*
do wave.do
onbreak {wave zoom full}
run -all
wave zoom full

