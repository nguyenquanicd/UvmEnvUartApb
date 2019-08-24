//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: UVM Testbench
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//--------------------------------------
class cTest extends uvm_test;
  //Register to Factory
	`uvm_component_utils(cTest)
  //Declare all instances
	cEnv coEnv;
	cVSequence coVSequence;
  //Constructor
	function new (string name = "cTest", uvm_component parent = null);
		super.new(name,parent);
	endfunction
  //Build phase
  //Create all objects by the method type_id::create()
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		coEnv = cEnv::type_id::create("coEnv",this);
		coVSequence = cVSequence::type_id::create("coVSequence",this);
	endfunction
  //Run phase
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		phase.raise_objection(this);
		fork
      begin
			  coVSequence.start(coEnv.coVSequencer);
      end
			begin
				#10s;
				`uvm_error("TEST SEQUENCE", "TIMEOUT!!!")
			end
		join_any
		disable fork;
		phase.drop_objection(this);
	endtask
endclass