//--------------------------------------
//Company: VLSI Technology
//Author: Quan Nguyen
//Function: UART TOP wrapper follows the naming rule.
//--------------------------------------
module m_fpt_uart_wrapper (
  //--------------------------------------
  //IO PAD
  //--------------------------------------
  /*AUTOINPUT("^i_uart_pad_")*/
  // Beginning of automatic inputs (from unused autoinst inputs)
  input			i_uart_pad_rx,		// To u_uart_top of uart_top.v
  // End of automatics
  /*AUTOOUTPUT("^o_uart_pad_")*/
  // Beginning of automatic outputs (from unused autoinst outputs)
  output		o_uart_pad_tx,		// From u_uart_top of uart_top.v
  // End of automatics
  //--------------------------------------
  //APB
  //--------------------------------------
  /*AUTOINPUT("^i_uart_apb_")*/
  // Beginning of automatic inputs (from unused autoinst inputs)
  input [31:0]		i_uart_apb_paddr,	// To u_uart_top of uart_top.v
  input			i_uart_apb_penable,	// To u_uart_top of uart_top.v
  input			i_uart_apb_psel,	// To u_uart_top of uart_top.v
  input [3:0]		i_uart_apb_pstrb,	// To u_uart_top of uart_top.v
  input [31:0]		i_uart_apb_pwdata,	// To u_uart_top of uart_top.v
  input			i_uart_apb_pwrite,	// To u_uart_top of uart_top.v
  // End of automatics
  /*AUTOOUTPUT("^o_uart_apb_")*/
  // Beginning of automatic outputs (from unused autoinst outputs)
  output [31:0]		o_uart_apb_prdata,	// From u_uart_top of uart_top.v
  output		o_uart_apb_pready,	// From u_uart_top of uart_top.v
  output		o_uart_apb_pslverr,	// From u_uart_top of uart_top.v
  // End of automatics
  //--------------------------------------
  //Interrupt
  //--------------------------------------
  /*AUTOOUTPUT("^o_uart_int_")*/
  // Beginning of automatic outputs (from unused autoinst outputs)
  output		o_uart_int_ctrl_fif,	// From u_uart_top of uart_top.v
  output		o_uart_int_ctrl_if,	// From u_uart_top of uart_top.v
  output		o_uart_int_ctrl_oif,	// From u_uart_top of uart_top.v
  output		o_uart_int_ctrl_pif,	// From u_uart_top of uart_top.v
  output		o_uart_int_ctrl_rif,	// From u_uart_top of uart_top.v
  output		o_uart_int_ctrl_tif,	// From u_uart_top of uart_top.v
  // End of automatics
  //--------------------------------------
  //Others
  //--------------------------------------
  /*AUTOINPUT*/
  // Beginning of automatic inputs (from unused autoinst inputs)
  input			i_uart_pclk,		// To u_uart_top of uart_top.v
  input			i_uart_preset_n	// To u_uart_top of uart_top.v
  // End of automatics
  /*AUTOOUTPUT*/
  /*AUTOINOUT*/
);
//--------------------------------------
// Do not generate the following input or output ports
//--------------------------------------
/* AUTO_LISP(setq verilog-auto-input-ignore-regexp
(concat
"unused_input"
"\\|unused_input_2"
"\\|unused_input_*_test"
)) */

/* AUTO_LISP(setq verilog-auto-output-ignore-regexp
(concat
"unused_output"
"\\|unused_output_2"
"\\|unused_output_*_test"
)) */

/*AUTOWIRE*/
/*AUTOREG*/

/* uart_top AUTO_TEMPLATE (
  .pclk             (i_uart_@"vl-name"[]),
  .preset_n         (i_uart_@"vl-name"[]),
  .ctrl_\(.*\)if    (o_uart_int_@"vl-name"[]),
  .p\(.*\)          (@"(if (equal vl-dir \\"input\\") \\"i_uart_apb_p\\" \\"o_uart_apb_p\\")"\1[]),
  .\(.*\)_\(rx\|tx\)(@"(if (equal vl-dir \\"input\\") \\"i_uart_pad_\\" \\"o_uart_pad_\\")"\2[]),
  .\(.*\)           (i_uart_@"vl-name"[]),
); */
uart_top u_uart_top (/*AUTOINST*/
		     // Outputs
		     .ctrl_if		(o_uart_int_ctrl_if),	 // Templated
		     .ctrl_fif		(o_uart_int_ctrl_fif),	 // Templated
		     .ctrl_oif		(o_uart_int_ctrl_oif),	 // Templated
		     .ctrl_pif		(o_uart_int_ctrl_pif),	 // Templated
		     .ctrl_rif		(o_uart_int_ctrl_rif),	 // Templated
		     .ctrl_tif		(o_uart_int_ctrl_tif),	 // Templated
		     .prdata		(o_uart_apb_prdata[31:0]), // Templated
		     .uart_tx		(o_uart_pad_tx),	 // Templated
		     .pready		(o_uart_apb_pready),	 // Templated
		     .pslverr		(o_uart_apb_pslverr),	 // Templated
		     // Inputs
		     .paddr		(i_uart_apb_paddr[31:0]), // Templated
		     .pclk		(i_uart_pclk),		 // Templated
		     .penable		(i_uart_apb_penable),	 // Templated
		     .preset_n		(i_uart_preset_n),	 // Templated
		     .psel		(i_uart_apb_psel),	 // Templated
		     .pwdata		(i_uart_apb_pwdata[31:0]), // Templated
		     .pwrite		(i_uart_apb_pwrite),	 // Templated
		     .pstrb		(i_uart_apb_pstrb[3:0]), // Templated
		     .uart_rx		(i_uart_pad_rx));	 // Templated

endmodule: m_fpt_uart_wrapper
// Local Variables:
// verilog-library-directory: ("." "./dut" "${DIR_HOME}/dut")
// verilog-library-extensions: (".v" ".sv" ".svh")
// verilog-auto-read-includes:t
// verilog-auto-star-expand: nil
// End:
