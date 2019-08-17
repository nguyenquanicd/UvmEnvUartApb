//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: User UVM Sequence - This is the TEST PATTERN created by user
//  - User modifty this class to create the expected transactions for the test purpose
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//Testcase : Regsiter check
// - Check initial values
// - 
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
    //Check initial values (uart_0 - TX)
    //--------------------------------------------
    //Control register
    `ApbReadTX(32'h00000000,32'h00000000,32'hffffffff)
    //Status/Enable register
    `ApbReadTX(32'h00000004,32'h00000020,32'hffffffff)
    //Baud rate register
    `ApbReadTX(32'h00000008,32'h00000000,32'hffffffff)
    //Data register
    `ApbReadTX(32'h0000000C,32'h00000000,32'hffffff00)
    //Interrupt enable register
    `ApbReadTX(32'h00000010,32'h00000000,32'hffffffff)
    //Raw Interrupt register
    `ApbReadTX(32'h00000014,32'h00000001,32'hffffffff)
    //Interrupt register
    `ApbReadTX(32'h00000018,32'h00000000,32'hffffffff)
    //--------------------------------------------
    //Check initial values (uart_1 - RX)
    //--------------------------------------------
    //Control register
    `ApbReadRX(32'h00000000,32'h00000000,32'hffffffff)
    //Status/Enable register
    `ApbReadRX(32'h00000004,32'h00000020,32'hffffffff)
    //Baud rate register
    `ApbReadRX(32'h00000008,32'h00000000,32'hffffffff)
    //Data register
    `ApbReadRX(32'h0000000C,32'h00000000,32'hffffff00)
    //Interrupt enable register
    `ApbReadRX(32'h00000010,32'h00000000,32'hffffffff)
    //Raw Interrupt register
    `ApbReadRX(32'h00000014,32'h00000001,32'hffffffff)
    //Interrupt register
    `ApbReadRX(32'h00000018,32'h00000000,32'hffffffff)
    //--------------------------------------------
    // ONLY check on uart_0 - TX from here
    //--------------------------------------------
    //Write/Read check (uart_0 - TX)
    //--------------------------------------------
    //Control register
    for (int i = 0; i < 16; i=i+1) begin
      `ApbWriteTX(32'h00000000,i)
      `ApbReadTX(32'h00000000,i,32'hffffffff)
    end
    //Status/Enable register
    //Do not check status bits
    for (int i = 0; i < 8; i=i+1) begin
      `ApbWriteTX(32'h00000004,i)
      `ApbReadTX(32'h00000004,i,32'hffffff1f)
    end
    //Baud rate register
    for (int i = 0; i < 256; i=i+1) begin
      `ApbWriteTX(32'h00000008,i)
      `ApbReadTX(32'h00000008,i,32'hffffffff)
    end
    //Interrupt enable register
    for (int i = 0; i < 32; i=i+1) begin
      `ApbWriteTX(32'h00000010,i)
      `ApbReadTX(32'h00000010,i,32'hffffffff)
    end
  endtask
endclass