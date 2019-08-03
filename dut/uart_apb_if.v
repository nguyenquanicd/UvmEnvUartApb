//--------------------------------------
//Project:  The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Module:   uart_apb_if
//Function:
// - APB interface - AMBA 4.0
// - Contain status/configuration registers
//Author:   NNguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet
//Page:     VLSI Technology
//--------------------------------------
`include "uart_define.h"
module uart_apb_if (/*AUTOARG*/
   // Outputs
   ctrl_en, ctrl_tx_en, ctrl_d9, ctrl_ep, ctrl_shift_rx, 
   ctrl_shift_tx, ctrl_txt, ctrl_rxt, ctrl_data_rd, ctrl_data,
   `ifdef INTERRUPT_COM 
   	  ctrl_if,
   `else 
      ctrl_tif, ctrl_rif, ctrl_oif, ctrl_pif, ctrl_fif,
   `endif
   prdata, pready, pslverr, pstrb,
   // Inputs
   pclk, preset_n, pwrite, psel, penable, paddr, pwdata, tx_nf, 
   tx_busy, tx_txe, rx_ne, rx_busy, rx_rxf, rx_ov, rx_pe, rx_fe, 
   rx_data
   );
  //
  // Input Signals
  //
  //APB interface
  input  pclk;
  input  preset_n;
  input  pwrite;
  input  psel;
  input  penable;
  input  [31:0] paddr;
  input  [31:0] pwdata;
  input  [3:0]  pstrb;
  //From Transmitter
  input  tx_nf;
  input  tx_busy;
  input  tx_txe;
  //From Receiver
  input  rx_ne;
  input  rx_busy;
  input  rx_rxf;
  input  rx_ov;
  input  rx_pe;
  input  rx_fe;
  input  [7:0] rx_data;
  //
  // Output Signals
  //
  output wire ctrl_en;
  output wire ctrl_tx_en;
  output wire ctrl_d9;
  output wire ctrl_ep;
  output wire ctrl_shift_rx;
  output wire ctrl_shift_tx;
  output wire [1:0]ctrl_txt;
  output wire [1:0]ctrl_rxt;
  output wire ctrl_data_rd;
  output wire [7:0]ctrl_data;
  output reg [31:0]prdata;
  output wire pready;
  output reg pslverr;
  `ifdef INTERRUPT_COM
  	output reg ctrl_if;
  `endif
  `ifndef INTERRUPT_COM
  	output wire ctrl_tif;
  	output wire ctrl_rif;
  	output wire ctrl_oif;
  	output wire ctrl_pif;
  	output wire ctrl_fif;
  `else
  	wire ctrl_tif;
  	wire ctrl_rif;
  	wire ctrl_oif;
  	wire ctrl_pif;
  	wire ctrl_fif;
  `endif
  // Internal Signals
  wire ctrl_busy;
  wire reg_sel;
  wire reg_we;
  wire reg_re;
  reg con_we;
  reg se_we;
  reg br_we;
  reg dt_we;
  reg ie_we;
  reg [3:0]con_reg;
  reg [2:0]se_reg;
  reg [7:0]br_reg;
  reg [4:0]ie_reg;
  reg [7:0] rx_counter;
  reg [3:0] tx_counter;
  wire err_condition;
  //
  // Body code
  //
  // Decoder Address
  assign reg_sel = psel & penable;
  assign reg_we = pwrite & reg_sel & (&pstrb[3:0]);
  assign reg_re = ~pwrite & reg_sel;
  always @ (*) begin
    con_we = 1'b0;
    se_we  = 1'b0;
    br_we  = 1'b0;
    dt_we  = 1'b0;
    ie_we  = 1'b0;
    case (paddr[4:0])
      5'b0_0000: con_we = reg_we; //h00
  		5'b0_0100: se_we  = reg_we; //h04
  		5'b0_1000: br_we  = reg_we; //h08
  		5'b0_1100: dt_we  = reg_we; //h0C
  		5'b1_0000: ie_we  = reg_we; //h10
		default: begin
		 con_we = 1'b0;
       se_we  = 1'b0;
       br_we  = 1'b0;
       dt_we  = 1'b0;
       ie_we  = 1'b0;
		end
    endcase
  end
  assign ctrl_tx_en = dt_we;
  assign ctrl_data_rd = reg_re & (paddr[4:0] == 5'b0_1100);
  // Control register
  always @(posedge pclk)begin
    if(~preset_n) con_reg[3:0] <= `DELAY 4'd0;
    else if(con_we) con_reg[3:0] <= `DELAY pwdata[3:0];
  end
  assign ctrl_txt[1:0] = con_reg[1:0];
  assign ctrl_rxt[1:0] = con_reg[3:2];
  //Enable register
  always @(posedge pclk)begin
    if(~preset_n) se_reg[2:0] <= `DELAY 3'd0;
    else if(se_we) se_reg[2:0] <= `DELAY pwdata[2:0];
  end
  assign ctrl_en = se_reg[0];
  assign ctrl_d9 = se_reg[1];
  assign ctrl_ep = se_reg[2]; 
  //Baud rate register
  always @(posedge pclk)begin
    if(~preset_n) br_reg[7:0] <= `DELAY 8'd0;
    else if(br_we) br_reg[7:0] <= `DELAY pwdata[7:0];
  end
  //Interrupt enable register
  always @(posedge pclk)begin
    if(~preset_n) ie_reg[4:0] <= `DELAY 5'd0;
    else if(ie_we) ie_reg[4:0] <= `DELAY pwdata[4:0];
  end
  // Interrupt signals
  assign ctrl_tif = tx_txe & ie_reg[0]; //Transmit Interrupt
  assign ctrl_rif = rx_rxf & ie_reg[1]; //Receiver Interrupt
  assign ctrl_oif = rx_ov  & ie_reg[2]; //Overflow Interrupt
  assign ctrl_pif = rx_pe  & ie_reg[3]; //Parity error Interrupt
  assign ctrl_fif = rx_fe  & ie_reg[4]; //Frame error Interrupt
  `ifdef INTERRUPT_COM
    always @ (posedge pclk) begin
      if (~preset_n) ctrl_if <= `DELAY 1'b0;
      else 
  	    ctrl_if <= `DELAY (ctrl_tif | ctrl_rif | ctrl_oif | ctrl_pif | ctrl_fif);
    end
  `endif
  //Transmit data
  assign ctrl_data[7:0] = pwdata[7:0];
  //Control busy signal
  assign ctrl_busy = tx_busy | rx_busy;
  //Read data decoder
  always @(*) begin
    case(paddr[4:0])
      5'b0_0000: prdata[31:0] = {28'd0, con_reg[3:0]};
  		5'b0_0100: prdata[31:0] = {24'd0, ctrl_busy, rx_ne, tx_nf, 2'd0, se_reg[2:0]};
  		5'b0_1000: prdata[31:0] = {24'd0, br_reg[7:0]};
  		5'b0_1100: prdata[31:0] = {24'd0, rx_data[7:0]};
  		5'b1_0000: prdata[31:0] = {27'd0, ie_reg[4:0]};
  		5'b1_0100: prdata[31:0] = {27'd0, rx_fe, rx_pe, rx_ov, rx_rxf, tx_txe};
  		5'b1_1000: prdata[31:0] = {27'd0, ctrl_fif, ctrl_pif, ctrl_oif, ctrl_rif, ctrl_tif};
  		default: prdata[31:0] = 32'd0;
    endcase
  end
  //Receiver Counter
  always @ (posedge pclk)begin
    if(~preset_n) rx_counter[7:0] <= `DELAY 8'd0;
    else begin
      casez({ctrl_shift_rx, ctrl_en})
  	  2'b?0: rx_counter[7:0] <= `DELAY 8'd0;
  	  2'b11: rx_counter[7:0] <= `DELAY 8'd0;
  	  2'b01: rx_counter[7:0] <= `DELAY rx_counter[7:0] + 1'b1;
  	  default: rx_counter[7:0] <= `DELAY 8'd0;
  	endcase
    end
  end
  assign ctrl_shift_rx = (rx_counter[7:0] == br_reg[7:0]);
  //Transmit Counter
  always @ (posedge pclk) begin
    if(~preset_n) tx_counter[3:0] <= `DELAY 4'd0;
    else begin
      casez({ctrl_shift_rx, ctrl_en})
  	  2'b?0: tx_counter[3:0] <= `DELAY 4'd0;
  	  2'b11: tx_counter[3:0] <= `DELAY tx_counter[3:0] + 1'b1;
  	endcase
    end
  end
  assign ctrl_shift_tx = (ctrl_shift_rx & (tx_counter[3:0] == 4'd15));
  //pready
  assign pready = 1'b1;
  //pslverr
  assign err_condition = (paddr[1:0] != 2'b00) //Address is not aligned 32-bit
                       | (paddr[15:0] > 16'h0018)   //Address is reserved
                       | (~&pstrb[3:0]) //Do not support pstrb[3:0] != 4'b1111
                       ;
  always @ (posedge pclk) begin
    if (~preset_n) pslverr <= `DELAY 1'b0;
    else if (psel) begin
      if (err_condition)
        pslverr <= `DELAY 1'b1;
      else
        pslverr <= `DELAY 1'b0;
    end
  end
endmodule