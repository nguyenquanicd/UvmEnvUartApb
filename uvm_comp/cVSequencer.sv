//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: Sequencer wraps Scoreboard, APB Agents
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//--------------------------------------
class cVSequencer extends uvm_sequencer#(cApbTransaction);
  //Register to Factory
	`uvm_component_utils(cVSequencer)
  //Declare all used instances
	cApbMasterAgent coApbMasterAgentTx;
	cApbMasterAgent coApbMasterAgentRx;
	cScoreboard coScoreboard;
  //
  // TODO: component must have variable "parent"
  // object must not have veriable "parent" (refer to class cVSequence) 
	function new (string name = "cVSequencer", uvm_component parent = null);
		super.new(name,parent);
    //Add more code if any
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
    //Add more code if any
	endfunction

endclass