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
      //Monitor interrupt enable
      monitor_ifEn ();
      //Detect interrupt
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
          coApbTransaction.pwdata[31:0] =  vifApbMaster.pwdata[31:0];
          coApbTransaction.prdata[31:0] =  vifApbMaster.prdata[31:0];
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
      #1ps
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
      #1ps
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
