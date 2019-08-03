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
    $display ("TESTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT 1\n");
		super.run_phase(phase);
		phase.raise_objection(this);
    $display ("TESTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT 2\n");
		fork
      begin
        $display ("TESTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT 3\n");
			  coVSequence.start(coEnv.coVSequencer);
        //`uvm_info(get_full_name(), "run phase completed.", UVM_LOW)
        $display ("TESTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT 4\n");
      end
			begin
				#1ms;
				`uvm_error("TEST SEQUENCE", "TIMEOUT!!!")
			end
		join_any
		disable fork;
		phase.drop_objection(this);
	endtask
endclass