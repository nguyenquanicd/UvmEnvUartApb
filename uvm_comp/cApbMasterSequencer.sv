//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB sequencer
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//--------------------------------------

class cApbMasterSequencer extends uvm_sequencer#(cApbTransaction);
	//Register to Factory
	`uvm_component_utils(cApbMasterSequencer)
  
  //Constructor
	function new (string name = "cApbMasterSequencer", uvm_component parent = null);
		super.new(name,parent);
	endfunction
endclass