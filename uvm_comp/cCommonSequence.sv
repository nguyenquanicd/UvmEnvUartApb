//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: Common sequences help create the user sequences easily
//  - User adds more the common sequences in this file
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//--------------------------------------

//--------------------------------------
//Write sequence
//--------------------------------------
class cApbMasterWriteSeq extends uvm_sequence#(cApbTransaction);
	`uvm_object_utils(cApbMasterWriteSeq)
	`uvm_declare_p_sequencer(cApbMasterSequencer)
  
  cApbTransaction coApbTransaction;
  
  rand logic conEn;
	rand logic [31:0] addr;
	rand logic [31:0] data;
	rand logic [ 3:0] be;	

	function new (string name = "cApbMasterWriteSeq");
		super.new(name);
    coApbTransaction = cApbTransaction::type_id::create("coApbTransaction");
	endfunction

	virtual task body();
		start_item(coApbTransaction);
    //coApbTransaction.randomize();
		assert(coApbTransaction.randomize() with {
      coApbTransaction.apbSeqEn  == 1;
      coApbTransaction.apbConEn  == conEn;
			coApbTransaction.paddr  == addr;
			coApbTransaction.pwdata == data;
			coApbTransaction.pstrb  == be;
			coApbTransaction.pwrite == 1;
		});
		finish_item(coApbTransaction);
	endtask
endclass
//--------------------------------------
//Read sequence
//--------------------------------------
class cApbMasterReadSeq extends uvm_sequence#(cApbTransaction);
	`uvm_object_utils(cApbMasterReadSeq)
	`uvm_declare_p_sequencer(cApbMasterSequencer)
  
  cApbTransaction coApbTransaction;
  
  rand logic conEn;
	rand logic [31:0] addr;
  rand logic [31:0] expectedReadData;
  rand logic [31:0] mask;
  logic [31:0] compareResult;

	function new (string name = "cApbMasterReadSeq");
		super.new(name);
    coApbTransaction = cApbTransaction::type_id::create("coApbTransaction");
	endfunction

	virtual task body();
   
		start_item(coApbTransaction);
		assert(coApbTransaction.randomize() with {
      coApbTransaction.apbSeqEn  == 1;
      coApbTransaction.apbConEn  == conEn;
			coApbTransaction.paddr  == addr;
			coApbTransaction.pwrite == 0;
		});
		finish_item(coApbTransaction);
    //Compare the actual data and the expected data
    compareResult = (coApbTransaction.prdata ^ expectedReadData) & mask;
    if (compareResult) begin
      `uvm_error("READ FAIL", $sformatf("Address: %8h, Expected data: %8h, Actual data: %8h, Mask: %8h", addr, expectedReadData, coApbTransaction.prdata, mask));
    end
	endtask
endclass
