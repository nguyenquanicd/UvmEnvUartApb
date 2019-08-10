#!/bin/perl

# #!/bin/perl

#---------------------------------------------
#The installed directory of Simulation tool 
#---------------------------------------------
my $SIM_TOOL = "C:/questasim64_10.2c/win64";
print "-- Simulate on $SIM_TOOL\n";

system "cp -f $ARGV[0] ../uvm_comp/.";
#---------------------------------------------
#Define all used tools
#---------------------------------------------
my $VLog    = "$SIM_TOOL/vlog.exe";
my $VSim    = "$SIM_TOOL/vsim.exe";

#---------------------------------------------
#Compilation
#---------------------------------------------
my $vlog = "$VLog -work work \\
  +define+UVM_CMDLINE_NO_DPI \\
  +define+UVM_REGEX_NO_DPI \\
  +define+UVM_NO_DPI \\
  +define+INTERRUPT_COM \\
  +incdir+C:/questasim64_10.2c/uvm-1.2/src \\
  -sv \\
  ../dut/uart_apb_if.v \\
  ../dut/uart_receiver.v \\
  ../dut/uart_transmitter.v \\
  ../dut/uart_top.v \\
  ../dut/dut_top.v \\
  ../checker/apb_protocol_checker.sv \\
  ../checker/apb_protocol_checker_top.sv \\
  ../checker/uart_protocol_checker.sv \\
  ../checker/uart_protocol_checker_top.sv \\
  ../uvm_comp/ifDut.sv \\
  testTop.sv \\
  -timescale 1ns/1ns \\
  -l vlog.log \\
  +cover";

system "$vlog";
  
#---------------------------------------------
#Simulation
#---------------------------------------------
my $vsim = "$VSim -c -novopt work.testTop \\
  +UVM_TESTNAME=cTest \\
  +UVM_VERBOSITY=UVM_LOW \\
  -do \"run -all\" \\
  -coverage \\
  -l vsim.log";

system "$vsim";

