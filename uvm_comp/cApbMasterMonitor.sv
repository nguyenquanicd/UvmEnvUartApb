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
			`uvm_error("NON-APBIF","Can NOT get vifApbMaster!!!")
		end
    //Check the interrupt connection
    if(!uvm_config_db#(virtual interface ifInterrupt)::get(this,"","vifInterrupt",vifInterrupt)) begin
			`uvm_error("NON-INTIF","Can NOT get vifInterrupt!!!")
		end
    //Create objects and analysis ports
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
      //Monitor interrupt enable
      monitor_ifEn ();
      //Detect interrupt
      detect_intf ();
		join
    
  endtask: run_phase	
  //Detect a completed APB transfer on the clock edge that ends the ACCESS phase
  // -> sample the signals (at the clock edge they still hold the values of the ACCESS cycle)
  // -> send a NEW copy of the transaction to analysis port ap_toScoreboard
  //    (a copy per transfer: the scoreboard may keep the handle)
  virtual task collect_data();
    cApbTransaction coCopy;
    while(1) begin
      @(posedge vifApbMaster.pclk);
      if (vifApbMaster.preset_n === 1'b1
      && vifApbMaster.psel === 1'b1 && vifApbMaster.penable === 1'b1 && vifApbMaster.pready === 1'b1) begin
        coCopy = cApbTransaction::type_id::create("coCopy");
        coCopy.paddr[31:0]  = vifApbMaster.paddr[31:0];
        coCopy.pstrb[3:0]   = vifApbMaster.pstrb[3:0];
        coCopy.pwrite       = vifApbMaster.pwrite;
        coCopy.pwdata[31:0] = vifApbMaster.pwdata[31:0];
        coCopy.prdata[31:0] = vifApbMaster.prdata[31:0];
        coCopy.pslverr      = vifApbMaster.pslverr;
        coCopy.pready       = 1;
        //Send the transaction to the analysis port which is connected to the Scoreboard
        ap_toScoreboard.write(coCopy);
      end
    end
  endtask
  //Send the reset status to the Scoreboard when it changes (and once at the start)
  virtual task detect_reset();
    logic last;
    last = 1'bx;
    while(1) begin
      @(posedge vifApbMaster.pclk);
      this.preset_n = vifApbMaster.preset_n;
      if (this.preset_n !== last) begin
        preset_toScoreboard.write(this.preset_n);
        last = this.preset_n;
      end
    end
  endtask
  //Detect interrupt toggle
  logic [4:0] ifEn = 5'd0;
  `ifdef INTERRUPT_COM
    logic ifSta = 1'b0;
  `else
    logic [4:0] ifSta = 5'd0;
  `endif
  virtual task monitor_ifEn ();
    //-------------------------------------
    // Update interrupt enable
    //-------------------------------------
    while (1) begin
      @(posedge vifApbMaster.pclk);
      if (vifApbMaster.psel && vifApbMaster.penable 
      && vifApbMaster.pready && vifApbMaster.pwrite 
      && (vifApbMaster.paddr[15:0] == 16'h0010)) begin
        //Use "<=" to make sure only check after enable
		    ifEn[4:0] <= vifApbMaster.pwdata[4:0];
		  end
    end
  endtask
  //
  virtual task detect_intf ();
    while(1) begin
      @(posedge vifApbMaster.pclk);
      //The interrupt outputs have no defined value while the reset is active: do not check them
      if (vifApbMaster.preset_n !== 1'b1) begin
        ifSta = '0;
        continue;
      end
      //-------------------------------------
      // Check the interrupt signals
      //-------------------------------------
      `ifdef INTERRUPT_COM
        if (vifInterrupt.ctrl_if) begin
          if (~ifSta) begin
            if (~|ifEn[4:0]) begin
              `uvm_error("cApbMasterMonitor", "INTERRUPT is toggled but NOT have any interrupt enable")
            end
            else begin
              `uvm_warning("cApbMasterMonitor", $sformatf("INTERRUPT is toggled when interrupt enable is %5b", ifEn[4:0]))
            end
          ifSta = 1'b1;
          end
        end
        else begin
          ifSta = 1'b0;
        end
      `else
        if (vifInterrupt.ctrl_tif) begin
          if (~ifSta[0]) begin
            if (~ifEn[0]) begin
              `uvm_error("cApbMasterMonitor", "Transmit interrupt is toggled but it is not enable")
            end
            else
              `uvm_warning("cApbMasterMonitor", "Transmit interrupt is toggled because TXFIFO is empty")
          end
          ifSta[0] = 1'b1;
        end
        else begin
          ifSta[0] = 1'b0;
        end
        //
        if (vifInterrupt.ctrl_rif) begin
          if (~ifSta[1]) begin
            if (~ifEn[1])
              `uvm_error("cApbMasterMonitor", "Receiver interrupt is toggled but it is not enable")
            else
              `uvm_warning("cApbMasterMonitor", "Receiver interrupt is toggled because RXFIFO is full")
          end
          ifSta[1] = 1'b1;
        end
        else begin
          ifSta[1] = 1'b0;
        end
        //
        if (vifInterrupt.ctrl_oif) begin
          if (~ifSta[2]) begin
            if (~ifEn[2])
              `uvm_error("cApbMasterMonitor", "Overflow interrupt is toggled but it is not enable")
            else
              `uvm_warning("cApbMasterMonitor", "Overflow interrupt is toggled because RXFIFO is full but a new UART frame is received")
          end
          ifSta[2] = 1'b1;
        end
        else begin
          ifSta[2] = 1'b0;
        end
        //
        if (vifInterrupt.ctrl_pif) begin
          if (~ifSta[3]) begin
            if (~ifEn[3])
              `uvm_error("cApbMasterMonitor", "Parity interrupt is toggled but it is not enable")
            else
              `uvm_warning("cApbMasterMonitor", "Parity interrupt is toggled because parity bit is wrong")
          end
          ifSta[3] = 1'b1;
        end
        else begin
          ifSta[3] = 1'b0;
        end
        //
        if (vifInterrupt.ctrl_fif) begin
          if (~ifSta[4]) begin
            if (~ifEn[4])
              `uvm_error("cApbMasterMonitor", "Frame error interrupt is toggled but it is not enable")
            else
              `uvm_warning("cApbMasterMonitor", "Frame error interrupt is toggled because STOP bit is 0")
          end
          ifSta[4] = 1'b1;
        end
        else begin
          ifSta[4] = 1'b0;
        end
      `endif
    end
  endtask
endclass
