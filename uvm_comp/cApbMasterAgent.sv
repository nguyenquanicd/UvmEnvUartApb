//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB Agent
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//--------------------------------------
class cApbMasterAgent extends uvm_agent;
  //Register to Factory
  `uvm_component_utils(cApbMasterAgent)
  //Declare Sequencer, Driver and Monitor
  cApbMasterDriver    coApbMasterDriver;
  cApbMasterSequencer coApbMasterSequencer;
  cApbMasterMonitor   coApbMasterMonitor;
  //Constructor
  function new(string name = "cApbMasterAgent", uvm_component parent);
      super.new(name, parent);
  endfunction
  //Build objects
  function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      coApbMasterDriver    = cApbMasterDriver::type_id::create("coApbMasterDriver",this);
      coApbMasterSequencer = cApbMasterSequencer::type_id::create("coApbMasterSequencer",this);
      coApbMasterMonitor   = cApbMasterMonitor::type_id::create("coApbMasterMonitor",this);
  endfunction
  //Connect Driver and Sequencer
  function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      coApbMasterDriver.seq_item_port.connect(coApbMasterSequencer.seq_item_export);
  endfunction
    
endclass