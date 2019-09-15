//--------------------------------------
//Project:  The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB scoreboard
//          - Compare data between data when write in data register and data when read from data register
//Authors:  Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton
//Page:     VLSI Technology
//--------------------------------------
// define the suffix name for declare the unique port and unique function name
`uvm_analysis_imp_decl(_frmMonitorTX)
`uvm_analysis_imp_decl(_frmMonitorRX)
`uvm_analysis_imp_decl(_resetfrmTX)

class cScoreboard extends uvm_scoreboard;
   //Register to Factory
   `uvm_component_utils(cScoreboard)
   // Data queue for storing the transmit data
   // of UARTs
   int queueTransTX[$];
   int queueTransRX[$];
   // Compared data
   int queueCompTX; //from queueCompTX
   int queueCompRX; //from queueCompRX
   // UART-TX and UART-RX enable status
   bit uartEnTX;
   bit uartEnRX;
   //Reset flag
   bit rst_flg;
   //Implement ports which receive the data sent from Monitor
   uvm_analysis_imp_frmMonitorTX #(cApbTransaction, cScoreboard) aimp_frmMonitorTX;
   uvm_analysis_imp_frmMonitorRX #(cApbTransaction, cScoreboard) aimp_frmMonitorRX;
   uvm_analysis_imp_resetfrmTX #(logic, cScoreboard) aimp_resetfrmTX;
   //declare the constructor for class, assign the initial value for class
   function new (string name = "cScoreboard", uvm_component parent);
      super.new(name, parent);
   endfunction
   
   function void build_phase (uvm_phase phase);
     super.build_phase(phase);
	   aimp_frmMonitorTX = new("aimp_frmMonitorTX", this); // declare object
	   aimp_frmMonitorRX = new("aimp_frmMonitorRX", this);
	   aimp_resetfrmTX = new("aimp_resetfrmTX", this);
	 endfunction
	 //Check the reset status
	 function void write_resetfrmTX (logic preset_n);
		 if (~preset_n) begin
		   rst_flg = 1'b1;
		   `uvm_info("SB RESET", $sformatf("[%t] preset_n signal is acting", $time), UVM_LOW)
		 end
     else begin
		   rst_flg = 1'b0;
     end
	 endfunction
	//
	function void write_frmMonitorTX(cApbTransaction TransOnTX);
		if (rst_flg == 1'b0) begin
      //-------------------------------------
      //Store transmit data to queue
      //-------------------------------------
		  // Update the enable status
		  if (TransOnTX.pwrite && (TransOnTX.paddr[15:0] == 16'h0004)) begin
		      uartEnTX = TransOnTX.pwdata[0];
		  end
      // Store transmit data to queues when UART is enabled
      // Only store 8 LSB bits, other MSB bits are mapped to 0
		  else if (TransOnTX.pwrite && (TransOnTX.paddr[15:0] == 16'h000C) && uartEnTX) begin
		      queueTransTX.push_back(TransOnTX.pwdata & 32'h0000_00ff);
		  end
      //-------------------------------------
      //Compare received data on UART-TX with queueTransRX on UART-RX
      //-------------------------------------
      else if (~TransOnTX.pwrite && (TransOnTX.paddr[15:0] == 16'h000C) && uartEnTX) begin
				//Get the transmitted data from queueCompRX
        queueCompRX = queueTransRX[0];
        //Compare the read data on UART-TX and transmitted data from UART-RX
        //Only compare 8 LSB bits
		    if ((TransOnTX.prdata & 32'h0000_00ff) == queueCompRX) begin
				  `uvm_info("SB INFO", $sformatf("[%t] SUCCESS on UART-TX: transfer data = %2h, queueTransRX size = %d", $time, TransOnTX.prdata, queueTransRX.size()), UVM_LOW);
				end
		    else begin
		      `uvm_error("SB ERROR", $sformatf("[%t] FAIL on UART-TX: read data = %2h, expected data =%2h, queueTransRX size = %d", $time, TransOnTX.prdata, queueCompRX, queueTransRX.size()))
        end
        //Delete queue
		    if (queueTransRX.size() != 0) begin 
				  queueTransRX.delete(0);
        end
        else begin
          `uvm_warning("SB UNFINISH-TX", "Read data but do NOT have any transmited data");
        end
		  end
    end
    else begin
      //Delete all entries of queue if reset is acting
      queueTransTX.delete();
      //Clear UART-TX enable
		  uartEnTX = 1'b0;
		end
  endfunction
	//
	function void write_frmMonitorRX(cApbTransaction TransOnRX);
		if (rst_flg == 1'b0) begin
      //-------------------------------------
      //Store transmit data to queue
      //-------------------------------------
		  // Update the enable status
		  if (TransOnRX.pwrite && (TransOnRX.paddr[15:0] == 16'h04)) begin
		      uartEnRX = TransOnRX.pwdata[0];
		  end
      // Store transmit data to queues when UART is enabled
      // Only store 8 LSB bits, other MSB bits are mapped to 0
		  else if (TransOnRX.pwrite && (TransOnRX.paddr[15:0] == 16'h0C) && uartEnRX) begin
		      queueTransRX.push_back(TransOnRX.pwdata & 32'h0000_00ff);
		  end
      //-------------------------------------
      //Compare received data on UART-RX with queueTransTX on UART-TX
      //-------------------------------------
      else if (~TransOnRX.pwrite && (TransOnRX.paddr[15:0] == 16'hC) && uartEnRX) begin
				//Get the transmitted data from queueCompTX
        queueCompRX = queueTransTX[0];
        //Compare the read data on UART-RX and transmitted data from UART-TX
        //Only compare 8 LSB bits
		    if ((TransOnRX.prdata & 32'h0000_00ff) == queueCompRX) begin
				  `uvm_info("SB INFO", $sformatf("[%t] SUCCESS on UART-RX: transfer data = %2h, queueTransTX size = %d", $time, TransOnRX.prdata, queueTransTX.size()), UVM_LOW);
				end
		    else begin
		      `uvm_error("SB ERROR", $sformatf("[%t] FAIL on UART-RX: read data = %2h, expected data =%2h, queueTransTX size = %d", $time, TransOnRX.prdata, queueCompRX, queueTransTX.size()))
        end
        //Delete queue
		    if (queueTransTX.size() != 0) begin 
				  queueTransTX.delete(0);
        end
        else begin
          `uvm_warning("SB UNFINISH-RX", "Read data but do NOT have any transmitted data");
        end
		  end
	  end
    else begin
      //Delete all entries of queue if reset is acting
      queueTransRX.delete();
      //Clear UART-TX enable
		  uartEnRX = 1'b0;
		end
  endfunction
  //
	function void report_phase(uvm_phase phase);
	   super.report_phase(phase);
     //
	   if (queueTransTX.size() != 0) begin
	     `uvm_warning("SB UNFINISH-TX", $sformatf("UART-TX: Queue is not empty, pending data: %d", queueTransTX.size()))
		 end
     //
     if (queueTransRX.size() != 0) begin
	     `uvm_warning("SB UNFINISH-RX", $sformatf("UART-RX: Queue is not empty, pending data: %d", queueTransRX.size()))
		 end
	endfunction

endclass: cScoreboard 