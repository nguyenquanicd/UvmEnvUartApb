//--------------------------------------
//Project:  The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB scoreboard
//          - Compare data between data when write in data register and data when read from data register
//Authors:  Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton
//Page:     VLSI Technology
//--------------------------------------

//--------------------------------------

// define the suffix name for declare the unique port and unique function name
`uvm_analysis_imp_decl(_frmMonitorTX)
`uvm_analysis_imp_decl(_frmMonitorRX)
`uvm_analysis_imp_decl(_resetfrmTX)
//`uvm_analysis_imp_decl(_resetfrmRX)


class cScoreboard extends uvm_scoreboard;

   `uvm_component_utils(cScoreboard)
   // declare queue for storing the data of each transaction
   int queue_transaction[$];
   // declare the variable, take the data oldest storing in queue
   int queue_compare;
   bit enTX ;
   bit enRX ;
   bit rst_flg;
   //Implement ports which receive the data sented from Monitor
   uvm_analysis_imp_frmMonitorTX #(cApbTransaction, cScoreboard) aimp_frmMonitorTX;
   uvm_analysis_imp_frmMonitorRX #(cApbTransaction, cScoreboard) aimp_frmMonitorRX;
   uvm_analysis_imp_resetfrmTX #(logic, cScoreboard) aimp_resetfrmTX;
   //uvm_analysis_imp_resetfrmRX #(logic, cScoreboard) aimp_resetfrmRX;
   
   //declare the constructor for class, assign the initial value for class
   function new (string name = "cScoreboard", uvm_component parent);
      super.new(name, parent);
   endfunction
   
   function void build_phase (uvm_phase phase);
      super.build_phase(phase);
	  aimp_frmMonitorTX = new("aimp_frmMonitorTX", this); // declare object
	  aimp_frmMonitorRX = new("aimp_frmMonitorRX", this);
	  aimp_resetfrmTX = new("aimp_resetfrmTX", this);
	//  aimp_resetfrmRX = new("aimp_resetfrmRX", this);
	endfunction
	
	//detect reset signal
	function void write_resetfrmTX (logic reset);
	    //`uvm_info("Get Reset TX",$sformatf("\npreset_n signal =%h, time =%0d",reset,$realtime), UVM_LOW)
		 if (~reset) begin
		   rst_flg = 1'b0;
		   //enTX = 1'b0;
		   //enRX = 1'b0;
		   `uvm_info("SB pending","Reset signal is acting", UVM_LOW)
		  // for (int i = 0; i <= queue_transaction.size(); i++) begin
		    //  if (queue_transaction.size() != 0) queue_transaction.delete(i) ;
			
			queue_transaction.delete() ;
			//end
		end else 
		   rst_flg = 1'b1;
	endfunction
	
	function void write_frmMonitorTX(cApbTransaction TransWrite);
	//`uvm_info(ID, MSG, VERBOSITY)
    //ID: message tag
    //MSG message text
	    //`uvm_info("Get_Trans TX", $sformatf("\n Transaction type=%h\n Transaction address=%h\n Transaction data=%h\n ",
		//    TransWrite.pwrite, TransWrite.paddr, TransWrite.pwdata), UVM_LOW)
		if (rst_flg == 1'b1) begin
			$display("no reset ");
		    // record the data of transaction send to module
		    if (TransWrite.pwrite &&(TransWrite.paddr[31:0] == 32'h04)) begin
		        enTX = TransWrite.pwdata[0];
		    end
		    if (TransWrite.pwrite &&(TransWrite.paddr[31:0] == 32'h0C) && (enTX == 1)) begin
		        queue_transaction.push_back(TransWrite.pwdata & 32'h0000_00ff);
		        // take the oldest data for comparing with the data output
			    // queue_compare = queue_transaction[0];
				 $display("compare data = %h",queue_compare);
				 $display("compare pwdata = %h",TransWrite.pwdata);
		    end //else if(enTX == 1'b0)
			// report warning when uart not enable
		    //    `uvm_warning("SB WARNING","UART TX not be enabled")
		    // Check transaction come when register empty
		   // if ((enTX == 1'b0) && ~TransWrite.pwrite && (TransWrite.paddr[31:0] == 32'hC)) begin
		    //    `uvm_warning("SB WARNING","Read trasaction come when register data is empty")
		   //  end
		end else begin
		//    for (int i = 0; i <= queue_transaction.size(); i++) begin
		//	    queue_transaction.delete(i);
		//	end
		     enTX = 1'b0;
		end
    endfunction
	
	// define and dump to the screen information about transaction type, data, address of each transactions	
	function void write_frmMonitorRX(cApbTransaction TransRead);
	   //`uvm_info("Get_Trans RX", $sformatf("\n Transaction type=%h\n Transaction address=%h\n Transaction data=%h\n ",
		//          TransRead.pwrite, TransRead.paddr, TransRead.pwdata), UVM_LOW)
		// Check the data when write and read
        // Match: report "PASS" 		
		// Mismatch: reprot "FAIL"
		if (rst_flg == 1'b1) begin
		    if (TransRead.pwrite && (TransRead.paddr[31:0] == 32'h4)) begin
		        enRX = TransRead.pwdata[0];
				//$display("data bit 6 = %h",TransRead.prdata[6]);
		    end
	        if (~TransRead.pwrite && (TransRead.paddr[31:0] == 32'hC) && (enRX == 1'b1)) begin
		        // compare data output with the oldest data in queue
				//$display("[UVM_HOANG] data bit 6 = %h",TransRead.prdata[6]);
				  queue_compare = queue_transaction[0];
		        if ((TransRead.prdata & 32'h0000_00ff) == queue_compare) begin  
		          //`uvm_info("SB PASS","The transaction write and read data from register are successful ", UVM_DEBUG)
			   // Delete the oldest data which recorded in queue.
		          if (queue_transaction.size() != 0) begin 
				     queue_transaction.delete(0);
					 $display("[SB INFO]size delete = %d", queue_transaction.size());
				  end
		        end else begin
		          `uvm_error("SB ERROR", $sformatf(" Mismatch data between read data = %h, expected data =%h  ",TransRead.prdata,queue_compare))
		        end
		   // end else if (enRX == 1'b0) begin
		   //       `uvm_warning("SB WARNING", "UART RX not be enabled")
		    end
	        // Check the read transaction come when nothing data from register
            if ((enRX == 0)  && ~TransRead.pwrite && (TransRead.paddr[31:0] == 32'hC))
		       `uvm_warning("SB WARNING", "UART not be enabled ")
		end else begin
		        enRX = 1'b0;
			end
    endfunction
    
	// Check queue is already empty when finish running 
	function void report_phase(uvm_phase phase);
	   super.report_phase(phase);
	   if (queue_transaction.size() != 0) begin
	   //   `uvm_info("SB FINISH", "Scoreboard finish", UVM_LOW)
	   //end else begin
	      `uvm_warning("SB UNFINISH", "Queue of scoreboard still contain data")
		  $display("size = %d", queue_transaction.size());
		end
	endfunction

endclass: cScoreboard 