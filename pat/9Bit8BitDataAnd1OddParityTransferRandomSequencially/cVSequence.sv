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
  int ExpDataArray[int];
  //logic [31:0] exptData;
  cApbMasterWriteSeq WriteSeq;
  cApbMasterReadSeq ReadSeq;
  cApbMasterWriteSeqNotCmpr ReadSeqWoCmpr;
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
    `ApbWriteTX(32'h00000008,32'h00000082) // parity bit is 0
    `ApbReadTX(32'h00000008,32'h00000082,32'h000000FF)
    //Enable UART TX
    `ApbWriteTX(32'h00000004,32'h00000003) // parity bit is 0
    `ApbReadTX(32'h00000004,32'h00000023,32'h000000FF)
    //--------------------------------------------
    //Setting UART-RX (uart_1)
    //--------------------------------------------
    //Set baud rate
    `ApbWriteRX(32'h00000008,32'h0000004B) // parity bit is 0
    `ApbReadRX(32'h00000008,32'h0000004B,32'h000000FF)
    //Enable UART TX
    `ApbWriteRX(32'h00000004,32'h00000003) // parity bit is 0
    `ApbReadRX(32'h00000004,32'h00000023,32'h000000FF)
    
    //RXFIFO đang chứa lớn hơn hoặc bằng 4 dữ liệu thì bit RXF của thanh ghi IR sẽ tích cực
    `ApbWriteRX(32'h00000000,32'h00000008) // parity bit is 0
    `ApbReadRX(32'h00000000,32'h00000008,32'h000000FF)
    //`ApbReadRX(32'h00000004, 32'h00000001, 32'hFFFFFFFF) //address, expected value, mask
    //
    //Write to DATA register of UART-TX to send data
    //Note: DATA only is 8-bit LSB
    //`ApbWriteTX(32'h0000000C,32'h00000000)
    //`ApbReadRX(32'h00000004,32'h000000A3,32'h000000ff)
    //while(1) begin
    //    `ApbReadWoCmprRX(32'h00000004)
    //    if(ReadSeqWoCmpr.coApbTransaction.prdata[6]) begin
    //        `ApbReadRX(32'h0000000C,32'h00000000,32'hffffffff)
    //        #100
    //        $stop;
    //    end
    //end
    
    for(int i = 0; i <= 3; i++) begin
        `ApbWriteRandTX(32'h0000000C)
         ExpDataArray[i] = WriteSeq.data;
         $display("ExpDataArray[%d] cpr %h",i,WriteSeq.data);
         end
        //`ApbReadRX(32'h00000004,32'h000000A3,32'h000000ff)
    while(1) begin
         `ApbReadWoCmprRX(32'h00000014)
         //if(ReadSeqWoCmpr.coApbTransaction.prdata[6] && !ReadSeqWoCmpr.coApbTransaction.prdata[7]) begin
         if(ReadSeqWoCmpr.coApbTransaction.prdata[1]) begin
         break;
         end   
     end
     
    for (int i = 0; i <= 3; i++) begin
     `ApbReadRX(32'h0000000C,ExpDataArray[i],32'h000000ff)
     $display("ExpDataArray[%d] cpr ---- %h",i,ExpDataArray[i]);
     #100ns;
    end 
         

    $stop;

  endtask
endclass