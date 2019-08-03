//--------------------------------------
//Project:  The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB scoreboard
//          - Compare data between data when write in data register and data when read from data register
//Authors:  Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton
//Page:     VLSI Technology
//--------------------------------------

//--------------------------------------
//`include "uvm.sv"
//import uvm_pkg::*;

`uvm_analysis_imp_decl(_frmMonitorWrite)
`uvm_analysis_imp_decl(_frmMonitorRead)
// define the suffix name for declare the unique port and unique function name
class cScoreboard extends uvm_scoreboard;

   `uvm_component_utils(cScoreboard)

  // TODO:  #(cScoreboard, cApbTransaction) khong dung, -->  #(cApbTransaction, cScoreboard) (fixed) 
   uvm_analysis_imp_frmMonitorWrite #(cApbTransaction, cScoreboard) aimp_frmMonitorWrite;
   uvm_analysis_imp_frmMonitorRead #(cApbTransaction, cScoreboard) aimp_frmMonitorRead;
   // define the unique port 
   //uvm_tlm_fifo #(coApbTransaction) get_frmMonitorWrite;
   //uvm_tlm_fifo #(coApbTransaction) get_frmMonitorRead;
   // get the transaction from monitor to fifo for calculating
   function new (string name = "cScoreboard", uvm_component parent);
      super.new(name, parent);
   endfunction
   
   function void build_phase (uvm_phase phase);
      super.build_phase(phase);
	  aimp_frmMonitorWrite = new("aimp_frmMonitorWrite", this);
	  aimp_frmMonitorRead = new("aimp_frmMonitorRead", this);
	  
	  //get_frmMonitorWrite = new("get_frmMonitorWrite", this);
	  //get_frmMonitorRead = new("get_frmMonitorRead", this);
	endfunction
	
	function void write_frmMonitorWrite(cApbTransaction TransWrite);
	//`uvm_info(ID, MSG, VERBOSITY)
    //ID: message tag
    //MSG message text
	    `uvm_info("Get_Trans APB1", $sformatf("Transaction type=%s\n Transaction address=%s\n Transaction data=%s\n ",
		          TransWrite.pwrite, TransWrite.paddr, TransWrite.pwdata), UVM_DEBUG)
    
	     //void '(get_frmMonitorWrite.try_put(TransWrite));
	endfunction
	// define and dump to the screen information about transaction type, data, address of each transactions	
	function void write_frmMonitorRead(cApbTransaction TransRead);
	   `uvm_info("Get_Trans APB1", $sformatf("Transaction type=%s\n Transaction address=%s\n Transaction data=%s\n ",
		          TransRead.pwrite, TransRead.paddr, TransRead.pwdata), UVM_DEBUG)
        // TODO: khong dung code nay
        //void '(get_frmMonitorRead.try_put(TransRead));
    endfunction
	// declare queue for storing the data of each transaction
   byte queue_transaction_1[$];
   // declare the variable, take the data oldest storing in queue
   bit queue_compare;
   virtual task run_phase(uvm_phase phase);
    // TODO: compile error - coApbTransaction khong ton tai, --> cApbTransaction (fixed) 
//    cApbTransaction Trans_write_side, Trans_read_side;
//	  
//	  forever begin
//	     `uvm_info("SB", "waiting for receiving the transaction at write side", UVM_DEBUG);
//		 // TODO: khong dung code nay
//		 //get_frmMonitorWrite.get(Trans_write_side);
//		 `uvm_info("SB", "waiting for receiving the transaction at read side", UVM_DEBUG);
//		 // get transaction from write macro 
//		 //TODO: Khong dung code nay
//		 //get_frmMonitorRead.get(Trans_write_side);
//		 // store the data in queue, if this transaction is write to data register
//		 if (Trans_write_side.pwrite && Trans_write_side.paddr[4:0] =='h0C) begin
//		    queue_transaction_1.push_back(Trans_read_side.pwdata);
//		// take the oldest data for comparing with the data output
//			queue_compare = queue_transaction_1.pop_front();
//		 end
//		 if (~Trans_read_side.pwrite && Trans_read_side.paddr[4:0] == 5'h0C) begin
//		 // compare data output with the oldest data in queue
//		    if (Trans_write_side.prdata == queue_compare) begin  
//			   `uvm_info("PASS", $sformatf("Write to data register =%s    Read from data register \n", 
//			    Trans_write_side.pwdata, Trans_read_side.prdata), UVM_DEBUG)
//			    queue_transaction_1.delete(0);
//			end else begin
//			    `uvm_info("ERROR", $sformatf("Write to data register =%s    Read from data register \n", 
//			              Trans_write_side.pwdata, Trans_read_side.prdata), UVM_DEBUG)
//			end
//		 end
//		 // check condition illegal when no data in register but read transaction come
//		 //if (queue_transaction_1 == null  && ~output_data.pwrite && output_data.paddr[4:0] == 5'h0C )
//		 //    `uvm_info("SB FAIL", "Read trasaction come when register data is empty", UVM_DEBUG)
//	  end
	endtask
	
	// Check queue is already empty when finish running scoreboard
	function void report_phase(uvm_phase phase);
	   super.report_phase(phase);
	   if (queue_transaction_1.size() == 0) begin
	      `uvm_info("COMPLETED", "Write and Read transaction succesfull", UVM_LOW )
	   end else 
	      `uvm_info("NOT COMPLETED", "Write and Read transaction fail", UVM_LOW)
	endfunction

endclass: cScoreboard

	
	   
	   
	   
    
   
   