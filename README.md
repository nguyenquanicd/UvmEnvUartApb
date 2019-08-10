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

Step 2: ./run_qsim.pl <your testcase link>

Example: ./run_qsim.pl ../pat/trialPat/cVSequence.sv

Note: Script run_qsim.pl will copy "../pat/trialPat/cVSequence.sv" to /UvmEnvUartApb/uvm_comp/ before executing

//--------------------------------------

//HOW TO CREATE A TESTCASE?

//--------------------------------------

Step 1: ./uvm_comp/cCommonSequence.sv - Create the common classes to control sequence

Step 2: ./uvm_comp/uMacro.sv - Create a macro which uses the object of a common class
in "Step 1" to read/write regsiters of UART

Step 3: ./pat/<your testcase name>/cVSequence.sv - Call expected macros in "Step 2" to read/write regsiters of UART

Note 1: You cannot use Macro but it help group a function and reduce code lines in cVSequence.sv

Note 2: One directory = one testcase

Note 3: Test case directory only contains cVSequence.sv which is your test pattern.


//Test Github Desktop
//Viet test Gibhub

END
