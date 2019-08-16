//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: User UVM Sequence - This is the TEST PATTERN created by user
//  - User modifty this class to create the expected transactions for the test purpose
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//--------------------------------------

class cVSequence extends uvm_sequence#(cApbTransaction);
  //Register to Factory
	`uvm_object_utils(cVSequence)
  `uvm_declare_p_sequencer(cVSequencer)
  
  cApbMasterWriteSeq WriteSeq;
  cApbMasterReadSeq ReadSeq;
  // Object must not have veriable "parent" (refer to class cVSequencer)
	function new (string name = "cVSequence");
		super.new(name);
	endfunction
  //TEST PATTERN is written at here
  task body();
    #50ns
    //--------------------------------------------
    //UART-TX (uart_0)
    //--------------------------------------------
    //check read/write BR register
	`ApbWriteTX(32'h00000008,32'h000000FF)
	//`ApbReadTX(32'h00000008, 32'h000000FF, 32'hFFFFFFFF)
	`ApbWriteTX(32'h00000008,32'h00000000)
	//`ApbReadTX(32'h00000008, 32'h00000000, 32'hFFFFFFFF)
	`ApbWriteTX(32'h00000008,32'hFFFFFFFF)
	//`ApbReadTX(32'h00000008, 32'hFFFFFFFF, 32'hFFFFFFFF)
	`ApbWriteTX(32'h00000008,32'h00000100)
	//`ApbReadTX(32'h00000008, 32'h00000100, 32'hFFFFFFFF)
	`ApbWriteTX(32'h00000008,32'h00000001)
	//`ApbReadTX(32'h00000008, 32'h00000001, 32'hFFFFFFFF)
    //--------------------------------------------
    //UART-RX (uart_1)
    //--------------------------------------------
    //check read/write BR register
	`ApbWriteRX(32'h00000008,32'h000000FF)
	`ApbReadRX(32'h00000008, 32'h000000FF, 32'hFFFFFFFF)
	`ApbWriteRX(32'h00000008,32'h00000000)
	`ApbReadRX(32'h00000008, 32'h00000000, 32'hFFFFFFFF)
	`ApbWriteRX(32'h00000008,32'hFFFFFFFF)
	`ApbReadRX(32'h00000008, 32'hFFFFFFFF, 32'hFFFFFFFF)
	`ApbWriteRX(32'h00000008,32'h00000100)
	`ApbReadRX(32'h00000008, 32'h00000100, 32'hFFFFFFFF)
	`ApbWriteRX(32'h00000008,32'h00000001)
	`ApbReadRX(32'h00000008, 32'h00000001, 32'hFFFFFFFF)
    // check offset
	`ApbWriteTX(32'h00000007,32'h000000EF)
	`ApbReadTX(32'h00000007, 32'h000000EF, 32'hFFFFFFFF)
	`ApbWriteTX(32'h00000008,32'h000000EF)
	`ApbReadTX(32'h00000008, 32'h000000EF, 32'hFFFFFFFF)
	`ApbWriteTX(32'h00000009,32'h000000EF)
	`ApbReadTX(32'h00000009, 32'h000000EF, 32'hFFFFFFFF)
	`ApbWriteTX(32'h0000000A,32'h000000EF)
	`ApbReadTX(32'h0000000A, 32'h000000EF, 32'hFFFFFFFF)
	`ApbWriteTX(32'h0000000B,32'h000000EF)
	`ApbReadTX(32'h0000000B, 32'h000000EF, 32'hFFFFFFFF)
	`ApbWriteTX(32'h0000000C,32'h000000EF)
	`ApbReadTX(32'h0000000C, 32'h000000EF, 32'hFFFFFFFF)
  endtask
endclass