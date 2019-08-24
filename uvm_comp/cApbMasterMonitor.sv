//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB sequencer
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//--------------------------------------
class cApbMasterMonitor extends uvm_monitor;
	`uvm_component_utils(cApbMasterMonitor)

	uvm_analysis_port #(cApbTransaction) ap_toScoreboard;
    	cApbTransaction coApbTransaction;
		
		//-----------------------
		// Just for test coverage
		bit a1;
		covergroup ABC;
		option.per_instance = 1;
		coverpoint a1;
		endgroup
		//-----------------------
	virtual interface ifApbMaster vifApbMaster;
  virtual interface ifInterrupt vifInterrupt;
	
	function new (string name = "cApbMasterMonitor", uvm_component parent = null);
		super.new(name,parent);
		//-----------------------
		// Just for test coverage
		ABC = new;
		ABC.sample();
		//-----------------------
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
    //Check the APB connection
		if(!uvm_config_db#(virtual interface ifApbMaster)::get(this,"","vifApbMaster",vifApbMaster)) begin
			`uvm_error("cApbMasterDriver","Can't get vifApbMaster!!!")
		end
    //Check the interrupt connection
    if(!uvm_config_db#(virtual interface ifInterrupt)::get(this,"","vifInterrupt",vifInterrupt)) begin
			`uvm_error("cVSequencer","Can't get vifInterrupt!!!")
		end
    //
    ap_toScoreboard = new("ap_toScoreboard", this);	
    coApbTransaction = cApbTransaction::type_id::create("coApbTransaction");
	endfunction

	virtual task run_phase(uvm_phase phase);

		super.run_phase(phase);
		collect_data( );
    	endtask: run_phase	
		// Add code here
    // vifApbMaster.pwrite => coApbTransaction.pwrite
    // Detect on APB interface
    // User flow
    // 1. Setting field A
    // 2. Setting field B
    // 3. Check UART enable
    // 4. Send configuration information
    virtual task collect_data( );
	forever begin
	wait(vifApbMaster.psel && vifApbMaster.penable && vifApbMaster.pready)
    //wait(vifApbMaster.psel);
	//coApbTransaction.paddr[31:0] =  vifApbMaster.paddr[31:0];
	//coApbTransaction.pstrb[3:0] = vifApbMaster.pstrb[3:0];
    //coApbTransaction.pwrite = vifApbMaster.pwrite;
	//do begin
        repeat(1) @(posedge vifApbMaster.pclk) begin
        //$display("VietHT UVM ----- DEBUG ---- 1 --- penable %1h --- pready %1h --- time: %t",vifApbMaster.penable,vifApbMaster.pready,$time);

             coApbTransaction.paddr[31:0] =  vifApbMaster.paddr[31:0];
             coApbTransaction.pstrb[3:0] = vifApbMaster.pstrb[3:0];
             coApbTransaction.pwrite = vifApbMaster.pwrite;
             
             if(vifApbMaster.penable == 1 && vifApbMaster.pready == 1) begin
            //$display("VietHT UVM ----- DEBUG ---- 2 --- penable %1h --- pready %1h --- time: %t",vifApbMaster.penable,vifApbMaster.pready,$time);
                if(coApbTransaction.pwrite == 1) begin
                coApbTransaction.pwdata[31:0] =  vifApbMaster.pwdata[31:0];
                end
                else begin
                coApbTransaction.prdata[31:0] =  vifApbMaster.prdata[31:0];
                end
                
                if(coApbTransaction.paddr[31:0] == 32'h04 && coApbTransaction.pwdata[31:0] == 32'h01) begin
                    //TODO: compile error - wr_data_reg khong co trong class coApbTransaction
                    //coApbTransaction.wr_data_reg = 1'b1;
                end
                else if (coApbTransaction.paddr[31:0] == 32'h04 && coApbTransaction.pwdata[31:0] == 32'h00) begin
                    //TODO: compile error - wr_data_reg khong co trong class coApbTransaction
                    //coApbTransaction.wr_data_reg = 1'b0;
                end 
            end
        end
	//end while(vifApbMaster.penable == 0 && vifApbMaster.pready == 0);
    //end while(vifApbMaster.psel == 0);
// Viet
		ap_toScoreboard.write(coApbTransaction);
	end
    endtask
endclass
