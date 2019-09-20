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
  
//------------------------------------------------
//Setting baudrate MIN (BRG = 32'hFF)
//------------------------------------------------
    #50ns
    //--------------------------------------------
    //Setting UART-TX (uart_0)
    //--------------------------------------------
    //Set baud rate
    `ApbWriteTX(32'h00000008,32'h000000FF) 
    `ApbReadTX(32'h00000008,32'h000000FF,32'hffffffff)
    //Enable
    `ApbWriteTX(32'h00000004,32'h00000003)
    `ApbReadTX(32'h00000004,32'h00000003,32'h00000001)
    //--------------------------------------------
    //Setting UART-RX (uart_1)
    //--------------------------------------------
    //Set baud rate
    `ApbWriteRX(32'h00000008,32'h00000FF) 
    `ApbReadRX(32'h00000008,32'h000000FF,32'hffffffff)
    //Enable
    `ApbWriteRX(32'h00000004,32'h00000003)
    `ApbReadRX(32'h00000004,32'h00000003,32'h00000001)
//---------------------------------------------------
// I, Send 32'h0 DATA continually
//---------------------------------------------------
	for (int i = 0; i < 8; i=i+1) begin
    `ApbWriteTX(32'h0000000C,32'h00000000)
    //Ccheck DATA on UART RX
     while (1) begin
      `ApbReadRX(32'h00000004,32'h00000040,32'h00000000)
      if (ReadSeq.coApbTransaction.prdata[6]) begin
        `ApbReadRX(32'h0000000C,32'h00000000,32'h000000ff)
        #50ns
        break;
      end
     end
	end
//---------------------------------------------------
// II, Send 32'hFF DATA continually
//---------------------------------------------------
	for (int i = 0; i < 8; i=i+1) begin
    `ApbWriteTX(32'h0000000C,32'h000000FF)
    //Ccheck DATA on UART RX
     while (1) begin
      `ApbReadRX(32'h00000004,32'h00000040,32'h00000000)
      if (ReadSeq.coApbTransaction.prdata[6]) begin
        `ApbReadRX(32'h0000000C,32'h000000FF,32'h000000ff)
        #50ns
        break;
      end
     end
	end	
//----------------------------------------------------------------
// III, Check full case
//----------------------------------------------------------------	
    for (int i = 0; i < 256; i=i+1) begin
      `ApbWriteTX(32'h0000000C,i)
      //Check DATA on UART RX
      while (1) begin
        `ApbReadRX(32'h00000004,32'h00000040,32'h00000000)
        if (ReadSeq.coApbTransaction.prdata[6]) begin
          `ApbReadRX(32'h0000000C,i,32'h000000ff)
          #50ns
          break;
        end
      end
	end
  endtask
endclass