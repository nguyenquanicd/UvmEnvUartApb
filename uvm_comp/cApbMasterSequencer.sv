//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB sequencer
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//--------------------------------------

class cApbMasterSequencer extends uvm_sequencer#(cApbTransaction);
	//Register to Factory
	`uvm_component_utils(cApbMasterSequencer)
	//Declare Instances to call in test pattern
	//cApbMasterAgent coApbMasterAgent;
  //Declare the interrupt interface  
  virtual interface ifInterrupt vifInterrupt;
  //Constructor
	function new (string name = "cApbMasterSequencer", uvm_component parent = null);
		super.new(name,parent);
    //Check the interrupt connection
    if(!uvm_config_db#(virtual interface ifInterrupt)::get(this,"","vifInterrupt",vifInterrupt)) begin
			`uvm_error("cVSequencer","Can't get vifInterrupt!!!")
		end
	endfunction
endclass