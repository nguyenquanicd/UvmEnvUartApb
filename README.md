# UvmEnvUartApb
//--------------------------------------

//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)

//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan

//Page:    VLSI Technology - https://nguyenquanicd.blogspot.com/

//--------------------------------------

This is the UVM environment for UART-APB IP core. This environment contains full UVM components. It is only used for studing and invetigating the UVM env.

Verification tool: Questa Sim -64 10.2c - Revision: 2013.07 - Date: Jul 19 2013

UVM library version: uvm1.2 from Accellera - https://workspace.accellera.org/downloads/standards/uvm

UART-APB IP core: seft-developed by authors

//--------------------------------------

//HOW TO RUN with QuestaSim GUI?

//--------------------------------------

cd /UvmEnvUartApb/sim/

Step 1: Open QuestaSim GUI

Step 2: Create a new project in UvmEnvUartApb/sim/

Step 3: Submit the command "Do run_sim.do" in "Transacript" window

Step 4: Choice "NO" when the finish window occurs

Step 5: View the result on Transacript and Waveform

//--------------------------------------

//HOW TO RUN BATCH MODE on Cygwin?

//Require: Install Cygwin and PERL

//--------------------------------------

cd /UvmEnvUartApb/sim/

Step 1: Modify the variable $SIM_TOOL in ./run_qsim.pl

Step 2: ./run_qsim.pl < your testcase name >

Example: ./run_qsim.pl trialPat

Note: Script run_qsim.pl will copy "../pat/trialPat/cVSequence.sv" to /UvmEnvUartApb/uvm_comp/ before executing

//--------------------------------------

//HOW TO CREATE A TESTCASE?

//--------------------------------------

Step 1: ./uvm_comp/cCommonSequence.sv - Create the common classes to control sequence

Step 2: ./uvm_comp/uMacro.sv - Create a macro which uses the object of a common class
in "Step 1" to read/write regsiters of UART

Step 3: ./pat/< your testcase name >/cVSequence.sv - Call expected macros in "Step 2" to read/write regsiters of UART

Note 1: You cannot use Macro but it help group a function and reduce code lines in cVSequence.sv

Note 2: One directory = one testcase

Note 3: Test case directory only contains cVSequence.sv which is your test pattern.

//--------------------------------------

//About baud rate

//--------------------------------------

UART-0 (TX) and UART-1 (RX) is assigned 2 different clocks, view sim/testTop.sv.

When you calculate the baudrate, please get the right frequency of UART-0/1.

Baud rate formula: BaudRate = f_UART/(16x(BRG+1))

BRG is the value set in baud rate register.

//--------------------------------------

//About coverage

//--------------------------------------

After each simulation, coverage is generated automatically,
report is saved to sim/index.html 
and a copy is stored in folder cov/ for merging coverage.
Using command "run_qsim.pl MERGE_COVERAGE" 
to merge coverage and generate report sim/index.html from this new database

//--------------------------------------

END
  
