//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: Monitor
//Author:  Truong Cong Hoang Viet, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Nguyen Hung Quan
//Page:    VLSI Technology
//--------------------------------------
class cApbMasterMonitor extends uvm_monitor;
  //Register to Factory
	`uvm_component_utils(cApbMasterMonitor)
  //Internal variables
  logic preset_n;
  cApbTransaction coApbTransaction;
  //Declare analysis ports
  uvm_analysis_port #(logic) preset_toScoreboard; 
  uvm_analysis_port #(cApbTransaction) ap_toScoreboard;
  //Declare the monitored interfaces
	virtual interface ifApbMaster vifApbMaster;
  virtual interface ifInterrupt vifInterrupt;
	//Constructor
	function new (string name = "cApbMasterMonitor", uvm_component parent = null);
		super.new(name,parent);
	endfunction
  //
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
    //Check the APB connection
		if(!uvm_config_db#(virtual interface ifApbMaster)::get(this,"","vifApbMaster",vifApbMaster)) begin
			`uvm_error("cApbMasterDriver","Can NOT get vifApbMaster!!!")
		end
    //Check the interrupt connection
    if(!uvm_config_db#(virtual interface ifInterrupt)::get(this,"","vifInterrupt",vifInterrupt)) begin
			`uvm_error("cVSequencer","Can NOT get vifInterrupt!!!")
		end
    //Create onjects and analysis ports
    ap_toScoreboard = new("ap_toScoreboard", this);	
	  preset_toScoreboard = new("preset_toScoreboard", this);
    coApbTransaction = cApbTransaction::type_id::create("coApbTransaction",this);
	endfunction
  //
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		fork
      //Detect transaction on APB interface and send to Scoreboard
		  collect_data();
      //Setect reset status and send to Scoreboard
		  detect_reset();
      //Monitor the interrupt ports and warning if they are toggle
      detect_intf ();
		join
  endtask: run_phase	
	//On each clock, detect a valid transaction
  // -> get the valid transaction
  // -> send the transaction to analysis port ap_toScoreboard
  virtual task collect_data();
	  while(1) begin
      @(posedge vifApbMaster.pclk) begin
        #1ps
        if(vifApbMaster.psel && vifApbMaster.penable && vifApbMaster.pready) begin
          //Get APB transaction on APB interface
          coApbTransaction.paddr[31:0] =  vifApbMaster.paddr[31:0];
          coApbTransaction.pstrb[3:0] = vifApbMaster.pstrb[3:0];
          coApbTransaction.pwrite = vifApbMaster.pwrite;
          if(vifApbMaster.pwrite == 1) begin
            coApbTransaction.pwdata[31:0] =  vifApbMaster.pwdata[31:0];
          end
          else begin
            coApbTransaction.prdata[31:0] =  vifApbMaster.prdata[31:0];
          end
          //Send the transaction to analysis port which is connected to Scoreboard
          ap_toScoreboard.write(coApbTransaction);
        end
      end
	  end
  endtask
	//On each clock, send the reset status to Scoreboard
  //via analysis port preset_toScoreboard
	virtual task detect_reset();
	  while(1) begin
			@(posedge vifApbMaster.pclk);
      #1ps
			this.preset_n = vifApbMaster.preset_n;
			preset_toScoreboard.write(this.preset_n);
		end
	endtask
  //Detect interrupt toggle
  virtual task detect_intf ();
    while(1) begin
      @(posedge vifApbMaster.pclk);
      #1ps
      `ifdef INTERRUPT_COM
        if (vifInterrupt.ctrl_if) begin
          `uvm_warning("cApbMasterMonitor", "INTERRUPT is toggled")
        end
      `else
        if (vifInterrupt.ctrl_tif) begin
          `uvm_warning("cApbMasterMonitor", "Transmit interrupt is toggled because TXFIFO is empty")
        end
        //
        if (vifInterrupt.ctrl_rif) begin
          `uvm_warning("cApbMasterMonitor", "Receiver interrupt is toggled because RXFIFO is full")
        end
        //
        if (vifInterrupt.ctrl_pif) begin
          `uvm_warning("cApbMasterMonitor", "Parity interrupt is toggled because parity bit is wrong")
        end
        //
        if (vifInterrupt.ctrl_oif) begin
          `uvm_warning("cApbMasterMonitor", "Overflow interrupt is toggled because RXFIFO is full but a new UART frame is received")
        end
        //
        if (vifInterrupt.ctrl_fif) begin
          `uvm_warning("cApbMasterMonitor", "Frame error interrupt is toggled because STOP bit is 0")
        end
      `endif
    end
  endtask
endclass
