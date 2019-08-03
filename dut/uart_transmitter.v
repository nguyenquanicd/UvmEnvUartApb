//--------------------------------------
//Project:  The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Module:   uart_transmitter
//Function: Transmit the serial data follow UART protocol
//Author:   Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet
//Page:     VLSI Technology
//--------------------------------------
`include "uart_define.h"
module  uart_transmitter(/*AUTOARG*/
   // Outputs
   tx_nf, tx_busy, tx_txe, uart_tx, 
   // Inputs
   pclk, preset_n, ctrl_data, ctrl_en, ctrl_tx_en, ctrl_d9, ctrl_ep, 
   ctrl_shift_tx, ctrl_txt
   );
  parameter IDLE = 1'b0;
  parameter TX_SHIFT = 1'b1;
  //input
  input pclk;
  input preset_n;
  input [7:0] ctrl_data;
  input ctrl_en;
  input ctrl_tx_en;
  input ctrl_d9;
  input ctrl_ep;
  input ctrl_shift_tx;
  input [1:0] ctrl_txt;
  //output
  output wire tx_nf;
  output wire tx_busy;
  output reg tx_txe;
  output wire uart_tx;
  //variables
  reg[3:0] shift_tx_counter;
  reg state;
  wire fsm_shift,fsm_idle;
  wire tx_shift_complete;
  wire shift_en;
  wire load_data;
  wire data9;
  wire [7:0] tx_fifo_out;
  reg [7:0] tx_mem_array [15:0];
  reg [4:0] tx_rptr;
  reg [4:0] tx_wptr;
  wire [4:0] data_num;
  reg  tx_fifo_ud, tx_fifo_ov;
  wire tx_fifo_re, tx_fifo_we;
  wire tx_fifo_full, tx_fifo_empty;
  reg [9:0] tx_shift_reg;
  wire tx_parity;
  wire tx_wr;
  //
  //Body
  //
  //Shift counter
  always @ (posedge pclk) begin
  	if(~preset_n)
      shift_tx_counter <= `DELAY 4'h0;
  	else if (~ctrl_en)
      shift_tx_counter <= `DELAY 4'h0;
  	else begin
  		casez({shift_en, tx_shift_complete})
  			2'b?1: shift_tx_counter <= `DELAY 4'd0;
  			2'b10: shift_tx_counter <= `DELAY shift_tx_counter+4'd1;
  		endcase
  	end
  end
  assign tx_shift_complete = ctrl_d9? (shift_tx_counter[3:0]==4'd10): (shift_tx_counter[3:0]==4'd9);
  assign load_data = ctrl_shift_tx & ~tx_fifo_empty & fsm_idle;
  assign shift_en  = fsm_shift& ctrl_shift_tx;
  assign data9     = ctrl_d9? tx_parity: 1'b1;
  assign tx_parity = ctrl_ep?(~(^tx_fifo_out)): (^tx_fifo_out);
  assign tx_busy   = ~(fsm_idle & tx_txe);
  //Transmit shift register
  always @ (posedge pclk) begin
  	if(~preset_n) 
  		tx_shift_reg <= `DELAY 10'h3ff;
  	else if(~ctrl_en)
  				tx_shift_reg <=`DELAY 10'h3ff;
  	else begin
  			case({load_data, shift_en})
  				2'b10: tx_shift_reg<= `DELAY {data9,tx_fifo_out[7:0],1'b0};
  				2'b01: tx_shift_reg<= `DELAY {1'b1, tx_shift_reg[9:1]};
  			endcase
  	end
  end
  assign uart_tx = tx_shift_reg[0];
  //FSM tcreates fsm_shift and fsm_idle signals
  always@(posedge pclk) begin
  	if(~preset_n)
      state <= `DELAY IDLE;
  	else if (~ctrl_en)
      state <= `DELAY IDLE;
  	else if ((state == IDLE) & load_data)
  		state <= `DELAY TX_SHIFT;
  	else if ((state == TX_SHIFT) & tx_shift_complete)
  		state <= `DELAY IDLE;
  end
  assign fsm_shift = state;
  assign fsm_idle = ~state;
  //
  // Transmit FIFO
  //
  //Read pointer
  always @(posedge pclk) begin
  	if(~preset_n)
      tx_rptr <= `DELAY 5'd0;
  	else if(~ctrl_en)
      tx_rptr <= `DELAY tx_wptr;
  	else if (tx_fifo_re)
      tx_rptr <= `DELAY tx_rptr + 5'd1;
  end
  //Write pointer
  always @ (posedge pclk) begin
  	if(~preset_n)
      tx_wptr <= `DELAY 5'd0;
  	else if(~ctrl_en)
  		tx_wptr <= `DELAY 5'd0;
  	else if (tx_fifo_we)
  		tx_wptr <= `DELAY tx_wptr + 5'd1;
  end
  //Empty, full flags of TXFIFO
  assign tx_fifo_empty = (tx_rptr[3:0]==tx_wptr[3:0]) & (tx_rptr[4]==tx_wptr[4]);
  assign tx_fifo_full  = (tx_rptr[3:0]==tx_wptr[3:0]) & (tx_rptr[4]!=tx_wptr[4]);
  assign data_num = tx_wptr - tx_rptr;
  always @ (*) begin
  	case(ctrl_txt[1:0])
  	  2'b00: tx_txe = (data_num == 0);
  	  2'b01: tx_txe = (data_num <= 2);
  	  2'b10: tx_txe = (data_num <= 4);
  	  2'b11: tx_txe = (data_num <= 8);
      default: tx_txe = 1'b0;
  	endcase
  end
  assign tx_nf = ~tx_fifo_full;
  assign tx_wr = ctrl_en & ctrl_tx_en;
  assign tx_fifo_re = load_data & ~tx_fifo_empty;
  assign tx_fifo_we = tx_wr & ~tx_fifo_full;
  //memory of TXFIFO
  always@(posedge pclk) begin
  	if(tx_fifo_we)
  	  tx_mem_array[tx_wptr[3:0]] <= `DELAY ctrl_data;
  end
  assign tx_fifo_out = tx_mem_array[tx_rptr[3:0]];
endmodule