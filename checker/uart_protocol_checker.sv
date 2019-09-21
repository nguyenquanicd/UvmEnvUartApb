//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: UART protocol checker
// - Check UART protocol must be mapped to UART standard
// - Check the bit width in the UART frame following the user configuration
//Severity:
// - [UART_ERROR]   - protocol error, must be corrected
// - [UART_WARNING] - must be check and consider
// - [UART_INFO]    - only is the information to debug or monitor
// - Default: Only print/display the UART_ERROR messages in the log file
//Author:  Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet
//Page:    VLSI Technology
//--------------------------------------
`ifndef UART_ERROR_SEVERITY
  `ifndef UART_WARNING_SEVERITY
    `ifndef UART_INFO_SEVERITY
      `define UART_ERROR_SEVERITY
    `endif
  `endif
`endif
//
`ifdef UART_WARNING_SEVERITY
  `define UART_ERROR_SEVERITY
`elsif UART_INFO_SEVERITY
  `define UART_ERROR_SEVERITY
  `define UART_WARNING_SEVERITY
`endif
`define DLYCHK #1
module uart_protocol_checker;
  //parameter
  parameter INST_NAME   = "UART_CHK_CHECKER";
  parameter INST_NET    = "uart_net";
  parameter CHK_UART_IDLE  = 1'b0;
  parameter CHK_UART_CHECK = 1'b1;
  //Clock and reset
  logic pclk;
  logic preset_n;
  //APB IF
  logic  pwrite;
  logic  psel;
  logic  penable;
  logic  pready;
  logic  [31:0] paddr;
  logic  [31:0] pwdata;
  logic  [3:0]  pstrb;
  //UART interface needs to check
  logic uart_net;
  //UART configuration information
  logic [2:0] apb_chk_se_info;
  logic [7:0] apb_chk_br_info;
  //
  //Internal variables
  //
  logic [12:0] bit_width;   //16*(apb_chk_br_info[7:0] + 1) => max = 4096 cycles
  logic [12:0] width_count; //16*(apb_chk_br_info[7:0] + 1) => max = 4096 cycles
  logic chk_uart_state;
  wire frame_start;
  wire frame_end;
  logic [3:0] bit_count;
  wire next_bit;
  logic uart_net_sync;
  wire uart_net_falling;
  wire uart_net_rising;
  wire [3:0] uart_bit_num;
  reg bitCheckedValue;
  reg baud_rate_error_sync;
  reg baud_rate_error_report;
  wire baud_rate_error_rising;
  //-------------------------------------------------
  // (1) Check "x" "z" on UART pin
  //-------------------------------------------------
  always @ (posedge pclk) begin
    if (preset_n) begin
      case (uart_net)
        1'bx: $display ("[UART_ERROR][%t][%s] %s is x\n", $time, INST_NAME, INST_NET);
        1'bz: $display ("[UART_ERROR][%t][%s] %s is z\n", $time, INST_NAME, INST_NET);
      endcase
    end
  end
  //-------------------------------------------------
  // (1) Detect the user settings via APB interface
  //-------------------------------------------------
  assign reg_sel = psel & penable & pready;
  assign reg_we = pwrite & reg_sel & (&pstrb[3:0]);
  assign se_we  = reg_we & (paddr[4:0] == 5'b0_0100);
  assign br_we  = reg_we & (paddr[4:0] == 5'b0_1000);
  //Enable register
  always @(posedge pclk)begin
    if(~preset_n) apb_chk_se_info[2:0] <= `DLYCHK 3'd0;
    else if(se_we) apb_chk_se_info[2:0] <= `DLYCHK pwdata[2:0];
  end
  //Baud rate register
  always @(posedge pclk)begin
    if(~preset_n) apb_chk_br_info[7:0] <= `DLYCHK 8'd0;
    else if(br_we) apb_chk_br_info[7:0] <= `DLYCHK pwdata[7:0];
  end
  //-------------------------------------------------
  // (1) FSM detect a UART frame
  //-------------------------------------------------
  //Synchronize the UART net
  // Detect the rising edge 
  // Detect the falling edge
  always @ (posedge pclk, negedge preset_n) begin
    if (~preset_n) uart_net_sync <= `DLYCHK 1'b1;
    else uart_net_sync <= `DLYCHK uart_net;
  end
  assign uart_net_rising  = ~uart_net_sync & uart_net;
  assign uart_net_falling = uart_net_sync & ~uart_net;
  //Select the number of bits of UART frame
  always @ (posedge pclk, negedge preset_n) begin
    if (~preset_n)
      chk_uart_state <= `DLYCHK CHK_UART_IDLE;
    else if (frame_start)
      chk_uart_state <= `DLYCHK CHK_UART_CHECK;
    else if (frame_end)
      chk_uart_state <= `DLYCHK CHK_UART_IDLE;
  end
  assign frame_end   = next_bit & apb_chk_se_info[0]
                       & (bit_count[3:0] == uart_bit_num[3:0]);
  assign frame_start = uart_net_falling & (~chk_uart_state | frame_end);
  //
  //Bit counter of UART frame
  //
  assign bit_count_clr = frame_end;
  assign bit_count_inc = (chk_uart_state == CHK_UART_CHECK) & next_bit;
  always @ (posedge pclk, negedge preset_n) begin
    if (~preset_n)
      bit_count[3:0] <= `DLYCHK 4'd0;
    else if (bit_count_clr)
      bit_count[3:0] <= `DLYCHK 4'd0;
    else if (bit_count_inc)
      bit_count[3:0] <= `DLYCHK bit_count[3:0] + 1'b1;
  end
  // Parity:    START - 8 DATA - 1 Parity - 1 STOP
  // No parity: START - 8 DATA - 1 STOP
  assign uart_bit_num[3:0] = apb_chk_se_info[1]? 4'd10: 4'd9;
  //UART bit width
  assign bit_width[12:0] = 16*(apb_chk_br_info[7:0] + 1'b1) - 1'b1;
  //Bit width counter
  assign next_bit = (width_count[12:0] == bit_width[12:0]);
  assign clr_width_count = next_bit;
  assign inc_width_count = chk_uart_state;
  always @ (posedge pclk, negedge preset_n) begin
    if (~preset_n) width_count[12:0] <= `DLYCHK 13'd0;
    else if (clr_width_count)
      width_count[12:0] <= `DLYCHK 13'd0;
    else if (inc_width_count)
      width_count[12:0] <= `DLYCHK width_count[12:0] + 1'b1;
  end
  //-------------------------------------------------
  // Timing (Pulse width) checking
  //-------------------------------------------------
  always @ (posedge pclk) begin
    if (preset_n & next_bit)
      bitCheckedValue <= `DLYCHK uart_net;
  end
  assign baud_rate_error = (bitCheckedValue != uart_net_sync) & chk_uart_state;
  always @ (posedge pclk, negedge preset_n) begin
    if (~preset_n) begin
      baud_rate_error_sync <= `DLYCHK 1'b0;
    end
    else begin
      baud_rate_error_sync <= `DLYCHK baud_rate_error;
    end
  end
  assign baud_rate_error_rising = ~baud_rate_error_sync & baud_rate_error;
  //
  always @ (posedge pclk, negedge preset_n) begin
    if (~preset_n) begin
      baud_rate_error_report <= `DLYCHK 1'b0;
    end
    else if (preset_n & baud_rate_error) begin
      baud_rate_error_report <= `DLYCHK 1'b1;
    end
  end
  //
  always @ (posedge pclk, negedge preset_n) begin
    if (preset_n & baud_rate_error_rising) begin
      $display ("[UART_ERROR][%t][%s] %s Bit width is violated  \n-- Expected bit value: %b\n-- Actual bit value: %b", $time, INST_NAME, INST_NET, bitCheckedValue, uart_net_sync);
    end
  end
  //-------------------------------------------------
  // Report at END of simulation
  //-------------------------------------------------
  final begin
    if (baud_rate_error_report) begin
      $display ("[UART_ERROR][%s][%s] Bit width is violated  ", $time, INST_NAME, INST_NET); 
    end
  end
endmodule