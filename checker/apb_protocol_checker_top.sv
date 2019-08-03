//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB protocol checker top
// - Connect APB protocol checker to APB interface which is checked
//Author:  Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet
//Page:    VLSI Technology
//--------------------------------------
module apb_protocol_checker_top;
  //Define the interface hierarchy
  `define apb0_if dut_top
  `define apb1_if dut_top
  //Checker connection
  apb_protocol_checker apb0_chk();
    assign apb0_chk.pclk     = `apb0_if.pclk_0;
    assign apb0_chk.preset_n = `apb0_if.preset_n_0;
    assign apb0_chk.pwrite   = `apb0_if.pwrite_0;
    assign apb0_chk.psel     = `apb0_if.psel_0;
    assign apb0_chk.penable   = `apb0_if.penable_0;
    assign apb0_chk.paddr    = `apb0_if.paddr_0;
    assign apb0_chk.pwdata   = `apb0_if.pwdata_0;
    assign apb0_chk.pstrb    = `apb0_if.pstrb_0;
    assign apb0_chk.prdata   = `apb0_if.prdata_0;
    assign apb0_chk.pready    = `apb0_if.pready_0;
    assign apb0_chk.pslverr  = `apb0_if.pslverr_0;
  
  apb_protocol_checker apb1_chk();
    assign apb1_chk.pclk     = `apb1_if.pclk_1;
    assign apb1_chk.preset_n = `apb1_if.preset_n_1;
    assign apb1_chk.pwrite   = `apb1_if.pwrite_1;
    assign apb1_chk.psel     = `apb1_if.psel_1;
    assign apb1_chk.penable   = `apb1_if.penable_1;
    assign apb1_chk.paddr    = `apb1_if.paddr_1;
    assign apb1_chk.pwdata   = `apb1_if.pwdata_1;
    assign apb1_chk.pstrb    = `apb1_if.pstrb_1;
    assign apb1_chk.prdata   = `apb1_if.prdata_1;
    assign apb1_chk.pready    = `apb1_if.pready_1;
    assign apb1_chk.pslverr  = `apb1_if.pslverr_1;
endmodule