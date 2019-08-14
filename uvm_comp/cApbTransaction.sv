//--------------------------------------
//Project:  The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB sequence
// - Create the APB transaction
//Authors:   Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet
//Page:     VLSI Technology
//--------------------------------------
//1. Create the new class by extending from uvm_sequence_item
class cApbTransaction extends uvm_sequence_item;
  //Parameters are used to control the procedure
  parameter APB_TRANSACTION_TIMEOUT = 32'd100;
  //2. Declare the data members controled by sequence
  //Note: the data members are declared with "rand" to enable create the random value
  //APB interface
  //rand logic psel; - Control by the driver
  //rand logic penable; - Control by the driver
  rand logic pwrite;  //Determine the transfer type: (0) READ or (1) WRITE
  rand logic [31:0] paddr;
  rand logic [31:0] pwdata;
  rand logic [3:0]  pstrb;
  logic [31:0] prdata;
  logic        pslverr;
  //Internal parameter to set the expected delay
  rand logic apbSeqEn;
  rand logic apbConEn;
  rand int   apbDelay;
  int pready = 1;
  //rand logic [1:0] apb_error_inject = 2'b00;
  //Limit the delay value from 0 to 15 time unit
  constraint delay_time {apbDelay inside {[0:15]};};
  //Register this class with the factory
  //allows access to the create method which is needed for cloning
  `uvm_object_utils_begin (cApbTransaction)
    //`uvm_field_int(data member, flag)
    //allow access to the functions copy, compare, pack, unpack, record, print, and sprint
    `uvm_field_int(pwrite, UVM_ALL_ON)
    `uvm_field_int(paddr, UVM_ALL_ON)
    `uvm_field_int(pwdata, UVM_ALL_ON)
    `uvm_field_int(pstrb, UVM_ALL_ON)
	`uvm_field_int(pready, UVM_ALL_ON)
    `uvm_field_int(apbDelay, UVM_ALL_ON)
    `uvm_field_int(apbSeqEn, UVM_ALL_ON)
    `uvm_field_int(apbConEn, UVM_ALL_ON)
  `uvm_object_utils_end
  //Constructor
  function new (string name = "cApbTransaction");
    super.new(name);
  endfunction: new
  //Show the value of all variable
  virtual task print_apb_seq();
     //`uvm_info(ID, MSG, VERBOSITY)
     //ID: message tag
     //MSG message text
     //get_full_name returns the full hierarchical name of the driver object
    `uvm_info("APB_SEQ", $sformatf("pwrite = %0h, paddr = %0h, pwdata = %0h, pstrb = %0h, prdata = %0h, apbDelay = %0d", pwrite, paddr, pwdata, pstrb, prdata, apbDelay), UVM_LOW);
  endtask: print_apb_seq

endclass: cApbTransaction