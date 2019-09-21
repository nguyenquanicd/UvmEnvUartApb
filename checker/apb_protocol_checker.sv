//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB protocol checker
// - Check APB protocol must be mapped to AMBA 3.0 APB
//Severity:
// - [APB_ERROR]   - protocol error, must be corrected
// - [APB_WARNING] - must be check and consider
// - [APB_INFO]    - only is the information to debug or monitor
// - Default: Only print/display the APB_ERROR messages in the log file
//Author:  Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet
//Page:    VLSI Technology
//--------------------------------------
`ifndef APB_ERROR_SEVERITY
  `ifndef APB_WARNING_SEVERITY
    `ifndef APB_INFO_SEVERITY
      `define APB_ERROR_SEVERITY
    `endif
  `endif
`endif
//
`ifdef APB_WARNING_SEVERITY
  `define APB_ERROR_SEVERITY
`elsif APB_INFO_SEVERITY
  `define APB_ERROR_SEVERITY
  `define APB_WARNING_SEVERITY
`endif
`define DLYCHK #1
module apb_protocol_checker;
  //
  //parameter
  //
  parameter INST_NAME   = "UART_CHK_CHECKER";
  parameter IDLE   = 2'd0;
  parameter SETUP_CHECK  = 2'd1;
  parameter ACCESS_CHECK = 2'd2;
  //
  //Interface
  //
  logic  pclk;
  logic  preset_n;
  logic  pwrite;
  logic  psel;
  logic  penable;
  logic  [31:0] paddr;  //Fix "0" or "1" for all unused/unchecked bits
  logic  [31:0] pwdata; //Fix "0" or "1" for all unused/unchecked bits
  logic  [3:0]  pstrb;  //Fix all 1s if it is unused
  logic [31:0] prdata;  //Fix "0" or "1" for all unused/unchecked bits
  logic pready;   //Fix "1" if it is unused
  logic pslverr;  //Fix "0" if it is unused
  //
  //Internal variables
  //
  logic [1:0] apb_state;
  logic [1:0] apb_next_state;
  logic paddr_or;
  logic pwdata_or;
  logic pstrb_or;
  logic prdata_or;
  logic pwrite_pre;
  logic [31:0] paddr_pre;
  logic [31:0] pwdata_pre;
  logic [3:0] pstrb_pre;
  logic pselReg;
  //
  //checker body
  //
  //Store the control information
  always @ (posedge pclk) begin
    pwrite_pre <= `DLYCHK pwrite;
    paddr_pre[31:0]  <= `DLYCHK paddr[31:0];
    pwdata_pre[31:0] <= `DLYCHK pwdata[31:0];
    pstrb_pre[3:0]  <= `DLYCHK pstrb[3:0];
  end
  //APB state register
  always @ (posedge pclk or negedge preset_n) begin
    if (~preset_n) apb_state <= `DLYCHK IDLE;
    else apb_state[1:0] <= `DLYCHK apb_next_state[1:0];
  end
  //
  //APB state monitor
  //
  always @ (*) begin
    case (apb_state[1:0])
      IDLE: begin
        apb_next_state[1:0] = SETUP_CHECK;
      end
      SETUP_CHECK: begin
        if (psel)
          apb_next_state[1:0] = ACCESS_CHECK;
        else
          apb_next_state[1:0] = SETUP_CHECK;
      end
      ACCESS_CHECK: begin
        if (penable & pready)
          apb_next_state[1:0] = SETUP_CHECK;
        else
          apb_next_state[1:0] = ACCESS_CHECK;
      end
      default: begin
        apb_next_state[1:0] = apb_state[1:0];
      end
    endcase
  end
  //Check following the BUS APB state
  always @ (posedge pclk) begin
    case (apb_state[1:0])
      IDLE: begin
      end
      SETUP_CHECK: begin
        if (psel) begin
          //Check 1
          if (penable) begin
            $display ("[APB_ERROR][%s][%t] PSEL and PENABLE are asserted 1 in the SETUP phase\n", INST_NAME, $time);
          end
        end
      end
      ACCESS_CHECK: begin
        //Check 1
        if (~penable) begin
          $display ("[APB_ERROR][%s][%t] PENABLE is not asserted 1 in the ACCESS phase\n", INST_NAME, $time);
        end
        //Check 2
        if (pwrite != pwrite_pre) begin
          $display ("[APB_ERROR][%s][%t] PWRITE is changed during PSEL=1\n", INST_NAME, $time);
        end
        //Check 3
        if (paddr[31:0] != paddr_pre[31:0]) begin
          $display ("[APB_ERROR][%s][%t] PADDR is changed during PSEL=1\n", INST_NAME, $time);
        end
        //Check 4
        if (pwrite) begin
          if (pwdata[31:0] != pwdata_pre[31:0]) begin
            $display ("[APB_ERROR][%s][%t] PWDATA is changed during PSEL=1 and PWRITE=1\n", INST_NAME, $time);
          end
          //
          if (pstrb[3:0] != pstrb_pre[3:0]) begin
            $display ("[APB_ERROR][%s][%t] PSTRB is changed during PSEL=1 and PWRITE=1\n", INST_NAME, $time);
          end
        end
        //
      end
    endcase
  end
  //Check all time after resetting
  assign paddr_or  = |paddr;
  assign pstrb_or  = |pstrb;
  assign pwdata_or = |pwdata;
  assign prdata_or = |prdata;
  always @ (posedge pclk) begin
    if (~preset_n)
      pselReg <= `DLYCHK 1'b0;
    else
      pselReg <= `DLYCHK psel;
  end
  always @ (posedge pclk) begin
    if (preset_n) begin
      //
      if (psel) begin
        //Check 1 - Only check at the first cycle
        //when psel is changed from 0 to 1
        if ((~pselReg) & penable) begin
          $display ("[APB_ERROR][%s][%t] PSEL and PENABLE are asserted 1 at the same time\n", INST_NAME, $time);
        end
        //Check 2
        case (penable)
          1'bx: $display ("[APB_ERROR][%s][%t] PENABLE is x\n", INST_NAME, $time);
          1'bz: $display ("[APB_ERROR][%s][%t] PENABLE is z\n", INST_NAME, $time);
        endcase
        //Check 3
        case (pwrite)
          1'bx: $display ("[APB_ERROR][%s][%t] PWRITE is x\n", INST_NAME, $time);
          1'bz: $display ("[APB_ERROR][%s][%t] PWRITE is z\n", INST_NAME, $time);
        endcase
        //Check 4
        case (paddr_or)
          1'bx: $display ("[APB_ERROR][%s][%t] PADDR is x\n", INST_NAME, $time);
          1'bz: $display ("[APB_ERROR][%s][%t] PADDR is z\n", INST_NAME, $time);
        endcase
        //Check 5
        if (pwrite) begin
          case (pstrb_or)
            1'bx: $display ("[APB_ERROR][%s][%t] PSTRB is x\n", INST_NAME, $time);
            1'bz: $display ("[APB_ERROR][%s][%t] PSTRB is z\n", INST_NAME, $time);
          endcase
        end
        //Check 6
        `ifdef APB_WARNING_SEVERITY
          if (pwrite) begin
            case (pwdata_or)
              1'bx: $display ("[APB_ERROR][%s][%t] PWDATA is x\n", INST_NAME, $time);
              1'bz: $display ("[APB_ERROR][%s][%t] PWDATA is z\n", INST_NAME, $time);
            endcase
          end
        `endif
        //Check 7
        case (pready)
          1'bx: $display ("[APB_ERROR][%s][%t] PREADY is x\n", INST_NAME, $time);
          1'bz: $display ("[APB_ERROR][%s][%t] PREADY is z\n", INST_NAME, $time);
        endcase
        //Check 8
        if (pready) begin
          case (pslverr)
            1'bx: $display ("[APB_ERROR][%s][%t] PSLVERR is x\n", INST_NAME, $time);
            1'bz: $display ("[APB_ERROR][%s][%t] PSLVERR is z\n", INST_NAME, $time);
          endcase
        end
        //Check 9
        if (pready) begin
          case (prdata_or)
            1'bx: $display ("[APB_ERROR][%s][%t] PRDATA is x\n", INST_NAME, $time);
            1'bz: $display ("[APB_ERROR][%s][%t] PRDATA is z\n", INST_NAME, $time);
          endcase
        end
      end
      //Check 10
      case (psel)
        1'bx: $display ("[APB_ERROR][%s][%t] PSEL is x\n", INST_NAME, $time);
        1'bz: $display ("[APB_ERROR][%s][%t] PSEL is z\n", INST_NAME, $time);
      endcase
    end
  end
  //
  //Debug information
  //
  `ifdef APB_INFO_SEVERITY
    always @ (posedge pclk) begin
      if (preset_n) begin
        if (psel & ~penable) begin
          if (pwrite) begin
            $display ("[APB_INFO][%s][%t] Starting a WRITE transaction PADDR=%8h PWDATA=%8h PSTRB=%4h\n", INST_NAME, $time, paddr, pwdata, pstrb);
          end
          else begin
            $display ("[APB_INFO][%s][%t] Starting a READ transaction PADDR=%8h\n", INST_NAME, $time, paddr);
          end
        end
        //
        if (psel & penable & pready) begin
          if (pwrite) begin
            $display ("[APB_INFO][%s][%t] Ending a WRITE transaction PADDR=%8h PWDATA=%8h PSTRB=%4h PSLVERR=%b\n", INST_NAME, $time, paddr, pwdata, pstrb, pslverr);
          end
          else begin
            $display ("[APB_INFO][%s][%t] Starting a READ transaction PADDR=%8h PRDATA=%h PSLVERR=%b\n", INST_NAME, $time, paddr, prdata, pslverr);
          end
        end
      end
    end
  `endif
  //
endmodule