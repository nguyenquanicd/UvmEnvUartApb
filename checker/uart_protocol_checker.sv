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
  logic  [31:0] paddr;
  logic  [31:0] pwdata;
  logic  [3:0]  pstrb;
  //UART interface needs to check
  logic uart_net;
  //UART configuration information
  logic [2:0] apb_chk_se_info;
  logic [7:0] apb_chk_br_info;
  //
  //
  //
  logic [12:0] bit_width;   //16*(apb_chk_br_info[7:0] + 1) => max = 4096 cycles
  logic [12:0] width_count; //16*(apb_chk_br_info[7:0] + 1) => max = 4096 cycles
  logic chk_uart_state;
  wire frame_start;
  wire frame_end;
  logic [3:0] bit_count;
  wire next_bit;
  logic [1:0] uart_net_sync;
  wire uart_net_falling;
  wire uart_net_rising;
  wire [3:0] uart_bit_num;
  logic [12:0] count_result;
  //
  //
  //
  always @ (posedge pclk) begin
    if (preset_n) begin
      if (uart_net == 1'bx || uart_net == 1'bz) begin
        $display ("[UART_ERROR][%t][%s] %s is x or z\n", $time, INST_NAME, INST_NET);
      end
    end
  end
  //
  //Detect the user settings
  //
  assign reg_sel = psel & penable;
  assign reg_we = pwrite & reg_sel & (&pstrb[3:0]);
  assign se_we  = reg_we & (paddr[4:0] == 5'b0_0100);
  assign br_we  = reg_we & (paddr[4:0] == 5'b0_1000);
  //Enable register
  always @(posedge pclk)begin
    if(~preset_n) apb_chk_se_info[2:0] <= 3'd0;
    else if(se_we) apb_chk_se_info[2:0] <= pwdata[2:0];
  end
  //Baud rate register
  always @(posedge pclk)begin
    if(~preset_n) apb_chk_br_info[7:0] <= 8'd0;
    else if(br_we) apb_chk_br_info[7:0] <= pwdata[7:0];
  end
  //
  //FSM
  //
  always @ (posedge pclk, negedge preset_n) begin
    if (~preset_n)
      chk_uart_state <= CHK_UART_IDLE;
    else if (frame_end)
      chk_uart_state <= CHK_UART_IDLE;
    else if (frame_start)
      chk_uart_state <= CHK_UART_CHECK;
  end
  assign frame_end   = (next_bit && apb_chk_se_info[1])?
                    (bit_count[3:0] == uart_bit_num[3:0]):
                    (bit_count[3:0] == uart_bit_num[3:0]);
  assign frame_start = uart_net_falling;
  //
  //Bit counter of UART frame
  //
  assign bit_count_clr = (chk_uart_state == CHK_UART_IDLE);
  assign bit_count_inc = (chk_uart_state == CHK_UART_CHECK) & next_bit;
  always @ (posedge pclk, negedge preset_n) begin
    if (~preset_n)
      bit_count[3:0] <= 4'd0;
    else if (bit_count_clr)
      bit_count[3:0] <= 4'd0;
    else if (bit_count_inc)
      bit_count[3:0] <= bit_count[3:0] + 1'b1;
  end
  //Synchronize the UART net
  // Detect the rising edge 
  // Detect the falling edge
  always @ (posedge pclk, negedge preset_n) begin
    if (~preset_n) uart_net_sync[1:0] <= 2'b11;
    else uart_net_sync[1:0] <= {uart_net_sync[0], uart_net};
  end
  assign uart_net_rising  = ~uart_net_sync[0] & uart_net;
  assign uart_net_falling = uart_net_sync[0] & ~uart_net;
  //Select the number of bits of UART frame
  // Parity:    START - 8 DATA - 1 Parity - 1 STOP
  // No parity: START - 8 DATA - 1 STOP
  assign uart_bit_num[3:0] = apb_chk_se_info[1]? 4'd10: 4'd9;
  //UART bit width
  assign bit_width[12:0] = 16*(apb_chk_br_info[7:0] + 1'b1) - 1'b1;
  //Bit width counter
  assign next_bit = (width_count[12:0] == bit_width[12:0]);
  assign clr_width_count = next_bit
                         | uart_net_falling
                         | uart_net_rising;
  assign inc_width_count = chk_uart_state;
  always @ (posedge pclk, negedge preset_n) begin
    if (~preset_n) width_count[12:0] <= 13'd0;
    else if (clr_width_count)
      width_count[12:0] <= 13'd1;
    else if (inc_width_count)
      width_count[12:0] <= width_count[12:0] + 1'b1;
  end
  //Detect the errors
  always @ (posedge pclk, negedge preset_n) begin
    if (~preset_n)
      count_result[12:0] <= 13'd0;
    else if (clr_width_count)
      count_result[12:0] <= width_count[12:0];
  end
  assign baud_rate_error = (width_count[12:0] % bit_width[12:0]) != 0; 
  always @ (posedge pclk) begin
    if (preset_n & baud_rate_error)
      $display ("[UART_ERROR][%t][%s] %s violated the bit width (baud rate error)\n-- Expected: %04d cycles\n-- Actual: %04d cycles", $time, INST_NAME, INST_NET, bit_width, width_count);
  end
endmodule