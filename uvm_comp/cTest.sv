//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: UVM Testbench
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//Fix log:
// - A timeout is an ERROR (it used to be a warning, so a test that hung still ended as "passed").
// - The timeout value is a run option: +TIMEOUT_NS=<ns>, default DEFAULT_TIMEOUT_NS.
// - report_phase prints one result line: "** TEST PASSED **" or "** TEST FAILED **".
//   Scripts (sim/run_qsim.pl, scripts/uartvip.py) read this line to set the exit status.
//--------------------------------------
class cTest extends uvm_test;
  //Register to Factory
  `uvm_component_utils(cTest)
  //Default timeout of one test: 100 ms of simulation time (the test is bounded, not endless)
  localparam longint unsigned DEFAULT_TIMEOUT_NS = 64'd100_000_000;
  //Declare all instances
  cEnv coEnv;
  cVSequence coVSequence;
  //Timeout value and status
  longint unsigned timeoutNs;
  bit timeoutHit;
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
    //Run option +TIMEOUT_NS=<ns>
    if (!$value$plusargs("TIMEOUT_NS=%d", timeoutNs)) begin
      timeoutNs = DEFAULT_TIMEOUT_NS;
    end
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
        #(timeoutNs * 1ns);
        timeoutHit = 1'b1;
        `uvm_error("CTEST TIMEOUT", $sformatf("The test pattern did not finish within %0d ns", timeoutNs))
      end
    join_any
    disable fork;
    phase.drop_objection(this);
  endtask
  //Print the result of the test
  function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    int unsigned nErr;
    super.report_phase(phase);
    svr  = uvm_report_server::get_server();
    nErr = svr.get_severity_count(UVM_ERROR) + svr.get_severity_count(UVM_FATAL);
    if (nErr == 0 && !timeoutHit) begin
      `uvm_info("TEST RESULT", "** TEST PASSED **", UVM_NONE)
    end
    else begin
      `uvm_info("TEST RESULT", $sformatf("** TEST FAILED ** errors=%0d timeout=%0d", nErr, timeoutHit), UVM_NONE)
    end
  endfunction
endclass
