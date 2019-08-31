//--------------------------------------
//Project:  The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB scoreboard
//          - Compare data between data when write in data register and data when read from data register
//Authors:  Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton
//Page:     VLSI Technology
//--------------------------------------

//--------------------------------------

`uvm_analysis_imp_decl(_frmMonitorTX)
`uvm_analysis_imp_decl(_frmMonitorRX)

// define the suffix name for declare the unique port and unique function name
class cScoreboard extends uvm_scoreboard;

   `uvm_component_utils(cScoreboard)
   // declare queue for storing the data of each transaction
   int queue_transaction[$];
   // declare the variable, take the data oldest storing in queue
   int queue_compare;
   //Implement ports which receive the data sented from Monitor
   uvm_analysis_imp_frmMonitorTX #(cApbTransaction, cScoreboard) aimp_frmMonitorTX;
   uvm_analysis_imp_frmMonitorRX #(cApbTransaction, cScoreboard) aimp_frmMonitorRX;
   //declare the constructor for class, assign the initial value for class
   function new (string name = "cScoreboard", uvm_component parent);
      super.new(name, parent);
   endfunction
   
   function void build_phase (uvm_phase phase);
      super.build_phase(phase);
	  aimp_frmMonitorTX = new("aimp_frmMonitorTX", this); // declare object
	  aimp_frmMonitorRX = new("aimp_frmMonitorRX", this);
	endfunction
	
	function void write_frmMonitorTX(cApbTransaction TransWrite);
	//`uvm_info(ID, MSG, VERBOSITY)
    //ID: message tag
    //MSG message text
	    `uvm_info("Get_Trans TX", $sformatf("\n Transaction type=%h\n Transaction address=%h\n Transaction data=%h\n ",
		          TransWrite.pwrite, TransWrite.paddr, TransWrite.pwdata), UVM_LOW)
		// record the data of transaction send to module
	     if (TransWrite.pwrite &&(TransWrite.paddr[4:0] == 5'h0c)) begin
		    queue_transaction.push_back(TransWrite.pwdata);
		// take the oldest data for comparing with the data output
			queue_compare = queue_transaction.pop_front();
		 end
    endfunction
	
	// define and dump to the screen information about transaction type, data, address of each transactions	
	function void write_frmMonitorRX(cApbTransaction TransRead);
	   `uvm_info("Get_Trans RX", $sformatf("\n Transaction type=%h\n Transaction address=%h\n Transaction data=%h\n ",
		          TransRead.pwrite, TransRead.paddr, TransRead.pwdata), UVM_LOW)
		// Check the data when write and read
        // Match: report "PASS" 		
		// Mismatch: reprot "FAIL"
	    if (~TransRead.pwrite && TransRead.paddr[4:0] == 5'h0c) begin
		 // compare data output with the oldest data in queue
		   if (TransRead.prdata == queue_compare) begin  
		      `uvm_info("SB PASS","The transaction write and read data from register are successful ", UVM_DEBUG)
			   // Delete the oldest data which recorded in queue.
			   //TODO
		      // queue_transaction.delete(0);
		   end else begin
		    `uvm_info("SB ERROR", "The transaction write and read data from register have been failed ", UVM_DEBUG)
		   end
		end
	   // Check the read transaction come when nothing data from register
       if (queue_transaction.size() == 0  && ~TransRead.pwrite && TransRead.paddr[4:0] == 5'h0C )
		 `uvm_info("SB FAIL", "Read trasaction come when register data is empty", UVM_DEBUG)
    endfunction
    
	// Check queue is already empty when finish running 
	function void report_phase(uvm_phase phase);
	   super.report_phase(phase);
	   if (queue_transaction.size() == 0) begin
	      `uvm_info("SB FINISH", "Scoreboard finish", UVM_LOW )
	   end else 
	      `uvm_info("SB UNFINISH", "Scoreboard not complete while simulation finish", UVM_LOW)
	endfunction

endclass: cScoreboard

	
	   
	   
	   
    
   
   