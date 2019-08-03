//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: Common sequences help create the user sequences easily
//  - User adds more the common sequences in this file
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//--------------------------------------

// Need to add other sequences (e.g. cApbMasterReadSeq)
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
   
  $display("Common Seq TEST 1\n"); 
		start_item(coApbTransaction);
    $display("Common Seq TEST 2\n"); 
    //coApbTransaction.randomize();
		assert(coApbTransaction.randomize() with {
      coApbTransaction.apbSeqEn  == 1;
      coApbTransaction.apbConEn  == conEn;
			coApbTransaction.paddr  == addr;
			coApbTransaction.pwdata == data;
			coApbTransaction.pstrb  == be;
			coApbTransaction.pwrite == 1;
		});
    $display("Common Seq TEST 3\n"); 
    $display("----%h \n", addr);
		finish_item(coApbTransaction);
	endtask
endclass