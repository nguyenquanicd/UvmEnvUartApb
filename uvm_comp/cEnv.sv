//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: UVM environment only contains the UVM components (Agents, Scoreboard, Sequencer)
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//--------------------------------------
//typedef class cApbMasterAgent;

class cEnv extends uvm_env;
  //Register to Factory
	`uvm_component_utils(cEnv)
  //Declare Agent, Scoreboard and Sequencer
	cApbMasterAgent coApbMasterAgentTx;
	cApbMasterAgent coApbMasterAgentRx;
	cScoreboard coScoreboard;
	cVSequencer coVSequencer;
  //Constructor
	function new (string name = "cEnv", uvm_component parent = null);
		super.new(name,parent);
	endfunction
  //Create the objects for Agent, Scoreboard and Sequencer
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		coApbMasterAgentTx = cApbMasterAgent::type_id::create("coApbMasterAgentTx",this);
		coApbMasterAgentRx = cApbMasterAgent::type_id::create("coApbMasterAgentRx",this);
		coScoreboard = cScoreboard::type_id::create("coScoreboard",this);
		coVSequencer = cVSequencer::type_id::create("coVSequencer",this);
	endfunction
  //Connect UVM components
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
    //Dynamic casting
		$cast(coVSequencer.coApbMasterAgentTx, this.coApbMasterAgentTx);
		$cast(coVSequencer.coApbMasterAgentRx, this.coApbMasterAgentRx);
        $cast(coVSequencer.coScoreboard, this.coScoreboard);
    //Connect Monitor and Scoreboard by TLM port
		coApbMasterAgentTx.coApbMasterMonitor.ap_toScoreboard.connect(coScoreboard.aimp_frmMonitorTX);
		coApbMasterAgentRx.coApbMasterMonitor.ap_toScoreboard.connect(coScoreboard.aimp_frmMonitorRX);
	endfunction
endclass
