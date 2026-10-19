//--------------------------------------
//Project:  The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB scoreboard
//          - Compare data between data when write in data register and data when read from data register
//Authors:  Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton
//Page:     VLSI Technology
//Fix log:
// - UART-RX and UART-TX use ONE checking function, so the two directions cannot diverge
//   (the RX path used to write the expected data to the TX variable).
// - A queue is checked for emptiness BEFORE its first entry is read (no read of an empty queue).
// - Reading data that was never sent is an error (UNDERFLOW), not a warning after the compare.
// - Reset clears both queues and both enable flags.
// - Data that is sent but never received before the end of the test is an error (UNFINISHED).
// - The scoreboard counts the compares, so a test that compared nothing is visible in the log.
//--------------------------------------
// define the suffix name for declare the unique port and unique function name
`uvm_analysis_imp_decl(_frmMonitorTX)
`uvm_analysis_imp_decl(_frmMonitorRX)
`uvm_analysis_imp_decl(_resetfrmTX)

class cScoreboard extends uvm_scoreboard;
   //Register to Factory
   `uvm_component_utils(cScoreboard)
   //Register addresses (16 LSB bits)
   localparam bit [15:0] ADDR_ENABLE = 16'h0004;
   localparam bit [15:0] ADDR_DATA   = 16'h000C;
   // Data queue for storing the transmit data of UARTs
   int queueTransTX[$];
   int queueTransRX[$];
   // UART-TX and UART-RX enable status
   bit uartEnTX;
   bit uartEnRX;
   //Reset flag
   bit rst_flg;
   //Statistics
   int unsigned cntCompareOk;
   int unsigned cntCompareErr;
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
   //On reset: forget all data in flight and clear both enable flags
   function void write_resetfrmTX (logic preset_n);
     if (~preset_n) begin
       rst_flg = 1'b1;
       queueTransTX.delete();
       queueTransRX.delete();
       uartEnTX = 1'b0;
       uartEnRX = 1'b0;
       `uvm_info("SB RESET", $sformatf("[%t] preset_n signal is acting", $time), UVM_LOW)
     end
     else begin
       rst_flg = 1'b0;
     end
   endfunction
   //Check one APB transfer of one UART
   // name  - "TX" or "RX", only used in the messages
   // en    - enable flag of this UART
   // own   - queue of data written by this UART (to be received by the other UART)
   // peer  - queue of data written by the other UART (to be received by this UART)
   function void check_uart (string name, cApbTransaction t, ref bit en, ref int own[$], ref int peer[$]);
     int expectedData;
     if (rst_flg) return;
     //Update the enable status
     if (t.pwrite && (t.paddr[15:0] == ADDR_ENABLE)) begin
       en = t.pwdata[0];
     end
     //Store transmit data when UART is enabled. Only the 8 LSB bits are used.
     else if (t.pwrite && (t.paddr[15:0] == ADDR_DATA) && en) begin
       own.push_back(t.pwdata & 32'h0000_00ff);
     end
     //Compare the received data with the data sent by the other UART
     else if (~t.pwrite && (t.paddr[15:0] == ADDR_DATA) && en) begin
       if (peer.size() == 0) begin
         cntCompareErr++;
         `uvm_error("SB UNDERFLOW", $sformatf("[%t] UART-%s read data = %2h but the other UART has not sent any data", $time, name, t.prdata[7:0]))
       end
       else begin
         expectedData = peer.pop_front();
         if ((t.prdata & 32'h0000_00ff) == expectedData) begin
           cntCompareOk++;
           `uvm_info("SB INFO", $sformatf("[%t] SUCCESS on UART-%s: received data = %2h, pending = %0d", $time, name, t.prdata[7:0], peer.size()), UVM_LOW)
         end
         else begin
           cntCompareErr++;
           `uvm_error("SB ERROR", $sformatf("[%t] FAIL on UART-%s: read data = %2h, expected data = %2h, pending = %0d", $time, name, t.prdata[7:0], expectedData, peer.size()))
         end
       end
     end
   endfunction
   //
   function void write_frmMonitorTX(cApbTransaction TransOnTX);
     check_uart("TX", TransOnTX, uartEnTX, queueTransTX, queueTransRX);
   endfunction
   //
   function void write_frmMonitorRX(cApbTransaction TransOnRX);
     check_uart("RX", TransOnRX, uartEnRX, queueTransRX, queueTransTX);
   endfunction
   //
   function void report_phase(uvm_phase phase);
     super.report_phase(phase);
     if (queueTransTX.size() != 0) begin
       `uvm_error("SB UNFINISH-TX", $sformatf("Data sent by UART-TX was never received by UART-RX, pending data: %0d", queueTransTX.size()))
     end
     if (queueTransRX.size() != 0) begin
       `uvm_error("SB UNFINISH-RX", $sformatf("Data sent by UART-RX was never received by UART-TX, pending data: %0d", queueTransRX.size()))
     end
     `uvm_info("SB SUMMARY", $sformatf("data compares: %0d passed, %0d failed", cntCompareOk, cntCompareErr), UVM_NONE)
   endfunction

endclass: cScoreboard
