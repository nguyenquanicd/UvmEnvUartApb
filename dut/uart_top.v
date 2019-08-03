//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Module:  TOP module of UART
//Function: Connect all sub-modules (uart_apb_if, uart_receiver and uart_transmitter)
//Author:  Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet
//Page:    VLSI Technology
//--------------------------------------
`include "uart_define.h"
module uart_top (/*AUTOARG*/
   // Outputs
   uart_tx, prdata, pready, pslverr, pstrb,
   `ifdef INTERRUPT_COM
     ctrl_if,
   `else
     ctrl_tif, ctrl_rif, ctrl_pif, ctrl_oif, ctrl_fif,
   `endif
   // Inputs
   uart_rx, pwrite, pwdata, psel, preset_n, penable, pclk, paddr
   );
/*AUTOINPUT*/
// Beginning of automatic inputs (from unused autoinst inputs)
input [31:0]		paddr;			// To ctrl of controller.v
input			pclk;			// To ctrl of controller.v, ...
input			penable;		// To ctrl of controller.v
input			preset_n;		// To ctrl of controller.v, ...
input			psel;			// To ctrl of controller.v
input [31:0]		pwdata;			// To ctrl of controller.v
input			pwrite;			// To ctrl of controller.v
input [3:0] pstrb;
input			uart_rx;		// To rx of receiver.v
// End of automatics

/*AUTOOUTPUT*/
// Beginning of automatic outputs (from unused autoinst outputs)
`ifdef INTERRUPT_COM
	output			ctrl_if;		// From ctrl of controller.v
`else
	output			ctrl_fif;		// From ctrl of controller.v
	output			ctrl_oif;		// From ctrl of controller.v
	output			ctrl_pif;		// From ctrl of controller.v
	output			ctrl_rif;		// From ctrl of controller.v
	output			ctrl_tif;		// From ctrl of controller.v
`endif
output [31:0]		prdata;			// From ctrl of controller.v
output			uart_tx;		// From tx of transmitter.v
output  pready;
output  pslverr;
// End of automatics

/*AUTOWIRE*/
// Beginning of automatic wires (for undeclared instantiated-module outputs)
wire			ctrl_d9;		// From ctrl of controller.v
wire [7:0]		ctrl_data;		// From ctrl of controller.v
wire			ctrl_data_rd;		// From ctrl of controller.v
wire			ctrl_en;		// From ctrl of controller.v
wire			ctrl_ep;		// From ctrl of controller.v
wire [1:0]		ctrl_rxt;		// From ctrl of controller.v
wire			ctrl_shift_rx;		// From ctrl of controller.v
wire			ctrl_shift_tx;		// From ctrl of controller.v
wire			ctrl_tx_en;		// From ctrl of controller.v
wire [1:0]		ctrl_txt;		// From ctrl of controller.v
wire			rx_busy;		// From rx of receiver.v
wire [7:0]		rx_data;		// From rx of receiver.v
wire			rx_fe;			// From rx of receiver.v
wire			rx_ne;			// From rx of receiver.v
wire			rx_ov;			// From rx of receiver.v
wire			rx_pe;			// From rx of receiver.v
wire			rx_rxf;			// From rx of receiver.v
wire			tx_busy;		// From tx of transmitter.v
wire			tx_nf;			// From tx of transmitter.v
wire			tx_txe;			// From tx of transmitter.v
// End of automatics

uart_apb_if apb_if (/*AUTOINST*/
		 // Outputs
		 .ctrl_en		(ctrl_en),
		 .ctrl_tx_en		(ctrl_tx_en),
		 .ctrl_d9		(ctrl_d9),
		 .ctrl_ep		(ctrl_ep),
		 .ctrl_shift_rx		(ctrl_shift_rx),
		 .ctrl_shift_tx		(ctrl_shift_tx),
		 .ctrl_txt		(ctrl_txt[1:0]),
		 .ctrl_rxt		(ctrl_rxt[1:0]),
		 .ctrl_data_rd		(ctrl_data_rd),
		 .ctrl_data		(ctrl_data[7:0]),
		 .prdata		(prdata[31:0]),
     .pready  (pready),
     .pslverr (pslverr),
		 `ifdef INTERRUPT_COM
		 .ctrl_if		(ctrl_if),
		 `else
		 .ctrl_tif		(ctrl_tif),
		 .ctrl_rif		(ctrl_rif),
		 .ctrl_oif		(ctrl_oif),
		 .ctrl_pif		(ctrl_pif),
		 .ctrl_fif		(ctrl_fif),
		 `endif
		 // Inputs
		 .pclk			(pclk),
		 .preset_n		(preset_n),
		 .pwrite		(pwrite),
		 .psel			(psel),
		 .penable		(penable),
		 .paddr			(paddr[31:0]),
		 .pwdata		(pwdata[31:0]),
     .pstrb     (pstrb[3:0]),
		 .tx_nf			(tx_nf),
		 .tx_busy		(tx_busy),
		 .tx_txe		(tx_txe),
		 .rx_ne			(rx_ne),
		 .rx_busy		(rx_busy),
		 .rx_rxf		(rx_rxf),
		 .rx_ov			(rx_ov),
		 .rx_pe			(rx_pe),
		 .rx_fe			(rx_fe),
		 .rx_data		(rx_data[7:0]));

uart_receiver receiver (/*AUTOINST*/
	     // Outputs
	     .rx_ne			(rx_ne),
	     .rx_busy			(rx_busy),
	     .rx_rxf			(rx_rxf),
	     .rx_ov			(rx_ov),
	     .rx_pe			(rx_pe),
	     .rx_fe			(rx_fe),
	     .rx_data			(rx_data[7:0]),
	     // Inputs
	     .pclk			(pclk),
	     .preset_n			(preset_n),
	     .ctrl_en			(ctrl_en),
	     .ctrl_d9			(ctrl_d9),
	     .ctrl_ep			(ctrl_ep),
	     .ctrl_shift_rx		(ctrl_shift_rx),
	     .ctrl_data_rd		(ctrl_data_rd),
	     .ctrl_rxt			(ctrl_rxt[1:0]),
	     .uart_rx			(uart_rx));

uart_transmitter transmitter (/*AUTOINST*/
		// Outputs
		.tx_nf			(tx_nf),
		.tx_busy		(tx_busy),
		.tx_txe			(tx_txe),
		.uart_tx		(uart_tx),
		// Inputs
		.pclk			(pclk),
		.preset_n		(preset_n),
		.ctrl_data		(ctrl_data[7:0]),
		.ctrl_en		(ctrl_en),
		.ctrl_tx_en		(ctrl_tx_en),
		.ctrl_d9		(ctrl_d9),
		.ctrl_ep		(ctrl_ep),
		.ctrl_shift_tx		(ctrl_shift_tx),
		.ctrl_txt		(ctrl_txt[1:0]));
endmodule