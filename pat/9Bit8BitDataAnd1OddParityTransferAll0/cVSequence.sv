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
    //Setting UART-TX (uart_0)
    //--------------------------------------------
    //Set baud rate
    `ApbWriteTX(32'h00000008,32'h00000001) // parity bit is 0
    `ApbReadTX(32'h00000008,32'h00000001,32'h000000FF)
    //Enable UART TX
    `ApbWriteTX(32'h00000004,32'h00000003) // parity bit is 0
    `ApbReadTX(32'h00000004,32'h00000003,32'h000000FF)
    //--------------------------------------------
    //Setting UART-RX (uart_1)
    //--------------------------------------------
    //Set baud rate
    `ApbWriteRX(32'h00000008,32'h00000001) // parity bit is 0
    `ApbReadRX(32'h00000008,32'h00000001,32'h000000FF)
    //Enable UART TX
    `ApbWriteRX(32'h00000004,32'h00000003) // parity bit is 0
    `ApbReadRX(32'h00000004,32'h00000003,32'h000000FF)
    //`ApbReadRX(32'h00000004, 32'h00000001, 32'hFFFFFFFF) //address, expected value, mask
    //
    //Write to DATA register of UART-TX to send data
    //Note: DATA only is 8-bit LSB
    `ApbWriteTX(32'h0000000C,32'h00000000)
    #50ns
    `ApbReadRX(32'h0000000C,32'h00000000)
  endtask
endclass