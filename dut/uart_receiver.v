//--------------------------------------
//Project:  The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Module:   uart_receiver
//Function: Receive the serial data follow UART protocol
//Author:   Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet
//Page:     VLSI Technology
//--------------------------------------
`include "uart_define.h"
module uart_receiver (
    //input
    pclk,
    preset_n,
    ctrl_en,
    ctrl_d9,
    ctrl_ep,
    ctrl_shift_rx,
    ctrl_data_rd,
    ctrl_rxt,
    uart_rx,
    //output
    rx_ne,
    rx_busy,
    rx_rxf,
    rx_ov,
    rx_pe,
    rx_fe,
    rx_data
    );
  //FSM
  parameter  IDLE_RX     = 2'b00;
  parameter  CHECK_START = 2'b01;
  parameter  SHIFT_DATA  = 2'b11;
  //
  // Input Signals
  //
  input wire pclk;
  input wire preset_n;
  input wire ctrl_en;
  input wire ctrl_d9;
  input wire ctrl_ep;
  input wire ctrl_shift_rx;
  input wire ctrl_data_rd;
  input wire [1:0]ctrl_rxt;
  input wire uart_rx;
  //
  // Output Signals
  //
  output wire rx_ne;
  output wire rx_busy;
  output reg rx_rxf;
  output wire rx_ov;
  output wire rx_pe;
  output wire rx_fe;
  output wire [7:0] rx_data;
  // Internal Signals
  wire set_sample_counter;
  reg [3:0] sample_counter;
  wire fsm_active;
  //wire set_rxcounter_bit;
  reg [3:0]rx_counter_bit;
  reg [1:0] ff_sync;
  reg [9:0] rx_shift_reg; 
  wire [7:0]data_in;
  wire frame_error;
  wire parity_error;
  wire uart_sync;
  wire rx_shift_en;
  wire rx_complete;
  reg fsm_start;
  reg fsm_shift;
  reg [1:0] rx_next_state;
  reg [1:0] rx_current_state;
  wire wr_rx_fifo;
  wire rd_rx_fifo;
  wire rx_fifo_empty; 
  wire rx_fifo_full;
  reg rx_fifo_ov;
  wire [4:0] rx_fifo_ptr_compare;
  wire [9:0] rx_fifo_data_out;
  wire lsb_rxfifo_equal;
  wire msb_rxfifo_diff; 
  wire [9:0]data_in_rx_fifo;
  reg [4:0] rx_wptr, rx_rptr;
  wire rx_fifo_we, rx_fifo_re;
  reg [9:0] rx_mem_array [15:0];
  //Sampler counter: determine the sampled position of a bit
  assign fsm_active = fsm_start | fsm_shift;
  assign set_sample_counter = fsm_active & ctrl_shift_rx;
  always @(posedge pclk) begin
    if(~preset_n) sample_counter[3:0] <= `DELAY 4'd0;
    else if (~ctrl_en) sample_counter[3:0] <= `DELAY 4'd0;
    else begin
      case({set_sample_counter, rx_complete})
        2'b01: sample_counter <= `DELAY 4'd0;
        2'b10: sample_counter <= `DELAY sample_counter + 1'b1;
      endcase
    end
  end
  //Shift enable
  assign rx_shift_en = ctrl_shift_rx & (sample_counter[3:0] == 4'd7);
  //Reciever counter: conut the number of the received bits
  always @(posedge pclk) begin
    if(~preset_n) rx_counter_bit[3:0] <= `DELAY 4'd0;
    else if (~ctrl_en) rx_counter_bit[3:0] <= `DELAY 4'd0;
    else begin
  	   case({rx_shift_en, rx_complete})
  		   2'b01: rx_counter_bit <= `DELAY 4'd0;
  		   2'b10: rx_counter_bit <= `DELAY rx_counter_bit + 1'b1;
  		 endcase
  	end
  end
  //Complete a received frame when all bits are sampled
  //Non-parity: START - 8 data bits - STOP
  //Parity: START - 8 data bits - Parity bit - STOP
  assign rx_complete = (ctrl_d9)? (rx_counter_bit[3:0] == 4'd11): (rx_counter_bit[3:0] == 4'd10);
  //Input synchronizer - 2FF
  always @(posedge pclk)begin
    if(~preset_n) ff_sync[1:0] <= `DELAY 2'b11;
    else ff_sync[1:0] <= `DELAY {ff_sync[0], uart_rx};
  end
  assign uart_sync = ff_sync[1];
  //Shift register: Sample a bit at the sampled point and store in this register
  //Right shift because the LSB is transfered first
  always @(posedge pclk)begin
    if(~preset_n) rx_shift_reg[9:0] <= `DELAY 10'b1111111111;
    else if(rx_shift_en) 
  		rx_shift_reg[9:0] <= `DELAY {uart_sync, rx_shift_reg[9:1]};
  end
  //
  //FSM of receiver
  //
  //Next state and outputs
  always @ (*) begin
    case(rx_current_state[1:0])
      IDLE_RX: begin
        //Output
  	    fsm_start = 1'b0;
  	    fsm_shift = 1'b0;
        //Next state
  	    if(~uart_sync)
          rx_next_state[1:0] = CHECK_START;
  	    else
          rx_next_state[1:0] = rx_current_state[1:0];
    	end
  	  CHECK_START: begin
        //Output
  	    fsm_start = 1'b1;
  	    fsm_shift = 1'b0;
  	    //Next state
  	    if(ctrl_shift_rx & uart_sync)
          rx_next_state[1:0] = IDLE_RX;
  	    else if (rx_shift_en)
          rx_next_state[1:0] = SHIFT_DATA;                 
  	    else
          rx_next_state[1:0] = rx_current_state[1:0];
  	  end
  	  SHIFT_DATA: begin
        //Outputs
  	    fsm_start = 1'b0;
  	    fsm_shift = 1'b1;
  	    //Next state
  	    if(rx_complete)
          rx_next_state[1:0] = IDLE_RX;
  	    else
          rx_next_state[1:0] = rx_current_state[1:0];
  	  end
  	  default: begin
  	    fsm_start = 1'b0;
  	    fsm_shift = 1'b0;
  	    rx_next_state[1:0] = IDLE_RX;
  	  end
    endcase
  end
  //
  //Current state register
  //
  always @(posedge pclk) begin
    if(~preset_n)
      rx_current_state[1:0] <= `DELAY  IDLE_RX;
    else if (~ctrl_en)
      rx_current_state[1:0] <= `DELAY  IDLE_RX;
    else
      rx_current_state[1:0] <= `DELAY rx_next_state[1:0];
  end
  //
  //Reciever FIFO
  //
  //Inputs of FIFO
  assign wr_rx_fifo = rx_complete;
  assign rd_rx_fifo = ctrl_data_rd;
  assign data_in[7:0] = ctrl_d9? rx_shift_reg[7:0] : rx_shift_reg[8:1] ;
  assign frame_error = ~rx_shift_reg[9];
  assign parity_error = ctrl_d9? (ctrl_ep? (^rx_shift_reg[8:0]) : ~(^rx_shift_reg[8:0])) :1'b0;
  assign data_in_rx_fifo[9:0] = {frame_error, parity_error, data_in[7:0]};
  //Outputs of FIFO
  assign rx_ne = ~rx_fifo_empty;
  assign rx_busy = fsm_active;
  always @ (*) begin
    case(ctrl_rxt[1:0])
      2'b00: rx_rxf = rx_fifo_full;
  	  2'b01: rx_rxf = (rx_fifo_ptr_compare[4:0] >= 5'd8);
  	  2'b10: rx_rxf = (rx_fifo_ptr_compare[4:0] >= 5'd4);
  	  2'b11: rx_rxf = (rx_fifo_ptr_compare[4:0] >= 5'd2);
  	  default: rx_rxf = 1'bx;
    endcase
  end
  assign rx_ov = rx_fifo_ov;
  assign rx_pe = rx_ne & rx_fifo_data_out[8];
  assign rx_fe = rx_ne & rx_fifo_data_out[9];
  assign rx_data[7:0] = rx_fifo_data_out[7:0];
  //
  //Write pointer
  //
  assign rx_fifo_we = rx_complete & ~rx_fifo_full;
  always @ (posedge pclk) begin
  	if(~preset_n)
      rx_wptr <=  `DELAY 5'd0;
  	else if(~ctrl_en)
      rx_wptr <=  `DELAY rx_rptr; //Clear FIFO by assigning wptr = rprt
  	else begin
  		if (rx_fifo_we)
        rx_wptr <=  `DELAY rx_wptr + 5'd1;
  		else
        rx_wptr <=  `DELAY rx_wptr;
  	end
  end
  //
  //Read pointer
  //
  assign rx_fifo_re = ctrl_data_rd & (~rx_fifo_empty);
  always @ (posedge pclk ) begin
    if(~preset_n)
      rx_rptr <=  `DELAY 5'd0;
  	else if (rx_fifo_re)
      rx_rptr <=  `DELAY rx_rptr + 5'd1;
  	else
      rx_rptr <=  `DELAY rx_rptr;
  end
  assign rx_fifo_ptr_compare = rx_wptr - rx_rptr;
  //Overload flag of RXFIFO
  always@ (posedge pclk) begin
    if (~preset_n)
      rx_fifo_ov <= `DELAY 1'b0;
    else begin
  	  casez ({(wr_rx_fifo & rx_fifo_full), rd_rx_fifo})
  	  	2'b?1 : rx_fifo_ov <= `DELAY 1'b0;
  	  	2'b10 : rx_fifo_ov <= `DELAY 1'b1;
  	  endcase
    end
  end
  //Full, empty flag of RXFIFO
  assign lsb_rxfifo_equal = (rx_wptr[3:0] == rx_rptr[3:0]);
  assign msb_rxfifo_diff  = rx_wptr[4] ^ rx_rptr[4];
  assign rx_fifo_full  = msb_rxfifo_diff & lsb_rxfifo_equal;
  assign rx_fifo_empty = ~msb_rxfifo_diff & lsb_rxfifo_equal;
  //Memory array of RXFIFO
  always@(posedge pclk) begin
  	if (rx_fifo_we)
      rx_mem_array[rx_wptr[3:0]] <= `DELAY data_in_rx_fifo[9:0];
  end
  //Data output of RXFIFO
  assign	rx_fifo_data_out[9:0] = rx_mem_array[rx_rptr[3:0]];

endmodule