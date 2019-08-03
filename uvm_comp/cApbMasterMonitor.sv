//`include "uvm.sv"
//import uvm_pkg::*;
//`include "apb_sequence.sv"
//`include "dut_interface.sv"
class cApbMasterMonitor extends uvm_monitor;
	`uvm_component_utils(cApbMasterMonitor)

	uvm_analysis_port #(cApbTransaction) ap_toScoreboardWrite;
    	cApbTransaction coApbTransaction;

	virtual interface ifApbMaster vifApbMaster;
	
	function new (string name = "cApbMasterMonitor", uvm_component parent = null);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual interface ifApbMaster)::get(this,"","vifApbMaster",vifApbMaster)) begin
			`uvm_error("cApbMasterDriver","Can't get vifApbMaster!!!")
		end
        ap_toScoreboardWrite = new("ap_toScoreboardWrite", this);	
        coApbTransaction = cApbTransaction::type_id::create("coApbTransaction");
		
		ap_toScoreboardWrite = new("toScoreboardWrite", this);
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
	wait(vifApbMaster.psel)
	coApbTransaction.paddr[31:0] =  vifApbMaster.paddr[31:0];
	coApbTransaction.pstrb[3:0] = vifApbMaster.pstrb[3:0];
	do begin
		repeat(1) @(posedge vifApbMaster.pclk);
		if(vifApbMaster.penable == 1 && vifApbMaster.pready == 1) begin	
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
	end while(vifApbMaster.penable == 0 && vifApbMaster.pready == 0);
// Viet
		ap_toScoreboardWrite.write(coApbTransaction);
	end
    endtask
endclass
