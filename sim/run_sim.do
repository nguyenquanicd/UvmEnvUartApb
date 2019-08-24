#---------------------------------------------
#Compilation
#---------------------------------------------
vlog -work work \
  +define+UVM_CMDLINE_NO_DPI \
  +define+UVM_REGEX_NO_DPI \
  +define+UVM_NO_DPI \
  +define+INTERRUPT_COM \
  +incdir+C:/questasim64_10.2c/uvm-1.2/src \
  -sv \
  ../dut/uart_apb_if.v \
  ../dut/uart_receiver.v \
  ../dut/uart_transmitter.v \
  ../dut/uart_top.v \
  ../dut/dut_top.v \
  ../checker/apb_protocol_checker.sv \
  ../checker/apb_protocol_checker_top.sv \
  ../checker/uart_protocol_checker.sv \
  ../checker/uart_protocol_checker_top.sv \
  ../uvm_comp/ifDut.sv \
  testTop.sv \
  -timescale 1ns/1ns \
  -l vlog.log \
  +cover
  
#---------------------------------------------
#Simulation
#---------------------------------------------
vsim -novopt work.testTop \
  +UVM_TESTNAME=cTest \
  +UVM_VERBOSITY=UVM_LOW \
  -coverage \
  -l vsim.log

#---------------------------------------------
#Add some signals to waveform before running
#---------------------------------------------
do add_wave.do

#---------------------------------------------
#Run
#---------------------------------------------
run -all

#---------------------------------------------
#Report the coverage result
#---------------------------------------------
coverage report -file {D:/20.Project/3.Github/New folder/UvmEnvUartApb/sim/cov_report.txt} -byfile -assert -directive -cvg -codeAll
