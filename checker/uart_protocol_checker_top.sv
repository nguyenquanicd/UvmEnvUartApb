//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB protocol checker top
// - Connect APB protocol checker to APB interface which is checked
//Author:  Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet
//Page:    VLSI Technology
//--------------------------------------
module uart_protocol_checker_top;
  //Define the interface hierarchy
  `define uart0_if dut_top
  `define uart1_if dut_top
  //Checker connection
  //UART 0 to UART 1
  
  uart_protocol_checker uart0_chk();
    defparam uart0_chk.INST_NAME = "uart0_chk";
    defparam uart0_chk.INST_NET  = "uart_0to1";
    //
    assign uart0_chk.pclk     = `uart0_if.pclk_0;
    assign uart0_chk.preset_n = `uart0_if.preset_n_0;
    assign uart0_chk.psel     = `uart0_if.psel_0;
    assign uart0_chk.penable  = `uart0_if.penable_0;
    assign uart0_chk.pwrite   = `uart0_if.pwrite_0;
    assign uart0_chk.paddr    = `uart0_if.paddr_0;
    assign uart0_chk.pwdata   = `uart0_if.pwdata_0;
    assign uart0_chk.pstrb    = `uart0_if.pstrb_0;
    assign uart0_chk.uart_net = `uart0_if.uart_0to1;
  
  //UART 1 to UART 0
  uart_protocol_checker uart1_chk();
    defparam uart1_chk.INST_NAME = "uart1_chk";
    defparam uart1_chk.INST_NET  = "uart_1to0";
    //
    assign uart1_chk.pclk     = `uart1_if.pclk_1;
    assign uart1_chk.preset_n = `uart1_if.preset_n_1;
    assign uart1_chk.psel     = `uart1_if.psel_1;
    assign uart1_chk.penable  = `uart1_if.penable_1;
    assign uart1_chk.pwrite   = `uart1_if.pwrite_1;
    assign uart1_chk.paddr    = `uart1_if.paddr_1;
    assign uart1_chk.pwdata   = `uart1_if.pwdata_1;
    assign uart1_chk.pstrb    = `uart1_if.pstrb_1;
    assign uart1_chk.uart_net = `uart1_if.uart_1to0;
    
endmodule