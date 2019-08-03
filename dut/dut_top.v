//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Module:  DUT top connects 2 UART instances
//Function: Instance 2 uart_top
//Author:  Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet
//Page:    VLSI Technology
//--------------------------------------
`include "uart_define.h"
module dut_top (
   //UART 0
   pclk_0, preset_n_0, pwrite_0, psel_0, penable_0, paddr_0,
   pwdata_0, pstrb_0, prdata_0, pready_0, pslverr_0,
   `ifdef INTERRUPT_COM
     ctrl_if_0,
   `else
     ctrl_tif_0, ctrl_rif_0, ctrl_pif_0, ctrl_oif_0, ctrl_fif_0,
   `endif
   //UART 1
   pclk_1, preset_n_1, pwrite_1, psel_1, penable_1, paddr_1,
   pwdata_1, pstrb_1, prdata_1, pready_1, pslverr_1,
   `ifdef INTERRUPT_COM
     ctrl_if_1,
   `else
     ctrl_tif_1, ctrl_rif_1, ctrl_pif_1, ctrl_oif_1, ctrl_fif_1,
   `endif
   //For UART protocol checker
   uart_0to1,
   uart_1to0
   );
  //
  //UART 0
  //
  input  pclk_0;
  input  preset_n_0;
  input  pwrite_0;
  input  psel_0;
  input  penable_0;
  input  [31:0] paddr_0;
  input  [31:0] pwdata_0;
  input  [3:0]  pstrb_0;
  output [31:0] prdata_0;
  output pready_0;
  output pslverr_0;
  `ifdef INTERRUPT_COM
	output			ctrl_if_0;
  `else
  	output			ctrl_fif_0;
  	output			ctrl_oif_0;	
  	output			ctrl_pif_0;	
  	output			ctrl_rif_0;	
  	output			ctrl_tif_0;	
  `endif
  //
  //UART 1
  //
  input  pclk_1;
  input  preset_n_1;
  input  pwrite_1;
  input  psel_1;
  input  penable_1;
  input  [31:0] paddr_1;
  input  [31:0] pwdata_1;
  input  [3:0]  pstrb_1;
  output [31:0] prdata_1;
  output pready_1;
  output pslverr_1;
    `ifdef INTERRUPT_COM
	output			ctrl_if_1;
  `else
  	output			ctrl_fif_1;
  	output			ctrl_oif_1;	
  	output			ctrl_pif_1;	
  	output			ctrl_rif_1;	
  	output			ctrl_tif_1;	
  `endif
  //
  //For UART protocol checker
  //
  output uart_0to1;
  output uart_1to0;
  //
  //instance
  //
  uart_top uart_0 (
  // Outputs
   .uart_tx (uart_0to1),
   .prdata  (prdata_0[31:0]),
   .pready  (pready_0),
   .pslverr (pslverr_0),
   .pstrb   (pstrb_0[3:0]),
   `ifdef INTERRUPT_COM
     .ctrl_if (ctrl_if_0),
   `else
     .ctrl_tif (ctrl_tif_0),
     .ctrl_rif (ctrl_rif_0),
     .ctrl_pif (ctrl_pif_0),
     .ctrl_oif (ctrl_oif_0),  
     .ctrl_fif (ctrl_fif_0),
   `endif
   // Inputs
   .uart_rx   (uart_1to0),
   .pwrite    (pwrite_0),
   .pwdata    (pwdata_0[31:0]),
   .psel      (psel_0),
   .preset_n  (preset_n_0),
   .penable   (penable_0),
   .pclk      (pclk_0),
   .paddr     (paddr_0[31:0])
  );
  
  uart_top uart_1 (
    // Outputs
   .uart_tx (uart_1to0),
   .prdata  (prdata_1[31:0]),
   .pready  (pready_1),
   .pslverr (pslverr_1),
   .pstrb   (pstrb_1[3:0]),
   `ifdef INTERRUPT_COM
     .ctrl_if (ctrl_if_1),
   `else
     .ctrl_tif (ctrl_tif_1),
     .ctrl_rif (ctrl_rif_1),
     .ctrl_pif (ctrl_pif_1),
     .ctrl_oif (ctrl_oif_1),  
     .ctrl_fif (ctrl_fif_1),
   `endif
   // Inputs
   .uart_rx   (uart_0to1),
   .pwrite    (pwrite_1),
   .pwdata    (pwdata_1[31:0]),
   .psel      (psel_1),
   .preset_n  (preset_n_1),
   .penable   (penable_1),
   .pclk      (pclk_1),
   .paddr     (paddr_1[31:0])
  );
endmodule