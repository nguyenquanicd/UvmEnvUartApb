//--------------------------------------
//Project:  The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: All interfaces
//Author:   Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet
//Page:     VLSI Technology
//--------------------------------------
//APB interface
//interface ifApbMaster (input logic pclk, input logic preset_n);
interface ifApbMaster;
  logic pclk;
  logic preset_n;
  logic psel;
  logic penable;
  logic pwrite;
  logic [31:0] paddr;
  logic [31:0] pwdata;
  logic [31:0] prdata;
  logic [3:0]  pstrb;
  logic        pready;
  logic        pslverr;
endinterface: ifApbMaster
//Interrupt interface 
interface ifInterrupt;
  `ifdef INTERRUPT_COM
    logic ctrl_if;
  `else
    logic ctrl_tif;
    logic ctrl_rif;
    logic ctrl_pif;
    logic ctrl_oif;  
    logic ctrl_fif;
   `endif
endinterface: ifInterrupt
//UART interface
interface ifUart (input logic pclk, input logic preset_n);
  logic uart_tx;
  logic uart_rx;
endinterface: ifUart