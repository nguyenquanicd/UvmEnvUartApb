//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB Driver
// - Convert the APB packet to APB transaction
// - Drive the APB signals
//Author:  Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet
//Page:    VLSI Technology
//--------------------------------------
//`include "uvm.sv"
//import uvm_pkg::*;
//`include "cApbTransaction.sv"
//`include "ifDut.sv"
class cApbMasterDriver extends uvm_driver #(cApbTransaction);
  //1. Declare the virtual interface
  virtual ifApbMaster uart_vifApbMaster;
  cApbTransaction ApbPacket;
  //2. Register to the factory
  //`uvm_component_utils is for non-parameterized classes
  `uvm_component_utils(cApbMasterDriver)
  //3. Class constructor with two arguments
  // - A string "name"
  // - A class object with data type uvm_component
  function new (string name, uvm_component parent);
    //Call the function new of the base class "uvm_driver"
    super.new(name, parent);
  endfunction: new
  //4. Build phase
  // - super.build_phase is called and executed first
  // - Configure the component before creating it
  // - Create the UVM component
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    //All of the functions in uvm_config_db are static, using :: to call them
    //If the call "get" is unsuccessful, the fatal is triggered
    if (!uvm_config_db#(virtual interface ifApbMaster)::get(.cntxt(this),
          .inst_name(""),
          .field_name("vifApbMaster"),
          .value(uart_vifApbMaster))) begin
       //`uvm_fatal(ID, MSG)
       //ID: message tag
       //MSG message text
       //get_full_name returns the full hierarchical name of the driver object
       `uvm_fatal("NON-APBIF", {"A virtual interface must be set for: ", get_full_name(), ".uart_vifApbMaster"})
     end
      //
      `uvm_info(get_full_name(), "Build phase completed.", UVM_LOW)
  endfunction
  //5. Run phase
  //Call 2 tasks for parallel execution
  virtual task run_phase (uvm_phase phase);
    fork
      reset_all ();
      get_seq_and_drive ();
    join
  endtask
  //
  //Methods
  //
  //Initiate all control signals when the reset is active
  //Run time: run until the end of the simulation
  virtual task reset_all();
    wait (~uart_vifApbMaster.preset_n) begin
      uart_vifApbMaster.psel    = 1'b0;
      uart_vifApbMaster.penable = 1'b0;
    end
    //
    while (1) begin
      @ (negedge uart_vifApbMaster.preset_n);
      //@ (posedge uart_vifApbMaster.pclk); //Reset of DUT is synchronize reset
      //if (~uart_vifApbMaster.preset_n) begin
        uart_vifApbMaster.psel    = 1'b0;
        uart_vifApbMaster.penable = 1'b0;
      //end
      //@ (posedge uart_vifApbMaster.preset_n);
      //`uvm_info (get_type_name(), "END of reset", UVM_LOW)
    end
    //
  endtask: reset_all
  //Initiate the communication with the sequencer to get a sequence (a transaction)
  //in non-reset mode
  //Run time: run until the end of the simulation
  virtual task get_seq_and_drive();
    forever begin
      @ (posedge uart_vifApbMaster.preset_n);
      while (uart_vifApbMaster.preset_n) begin
        $display ("preset_n: %b", uart_vifApbMaster.preset_n);
        //if (uart_vifApbMaster.preset_n) begin
          //The seq_item_port.get_next_item is used to get items from the sequencer
          seq_item_port.get_next_item(ApbPacket);
          $display ("ApbPacket: %h", ApbPacket);
          //req is assigned to convert_seq2apb to drive the APB interface
          convert_seq2apb(ApbPacket);
          //Report the done execution
          seq_item_port.item_done();
        //end
      end
    end
  endtask: get_seq_and_drive
  //
  virtual task convert_seq2apb (cApbTransaction userApbTransaction);
    //Note:
    // 1. psel of cApbTransaction is used an valid flag of an APB packet
    // 2. penable of cApbTransaction is not used
    //Only use a sequence with apbSeqEn = 1
    if (userApbTransaction.apbSeqEn) begin
      //Initiate a transfer by a rising edge of the APB clock
      //If this transfer is back-to-back with the previous transfer,
      //one delay cycle is not inserted
      if (userApbTransaction.apbConEn == 0) begin
        repeat (1) @ (posedge uart_vifApbMaster.pclk);
      end
      //SETUP state of APB protocol
      uart_vifApbMaster.psel         = 1'b1;
      uart_vifApbMaster.pwrite       = userApbTransaction.pwrite;
      uart_vifApbMaster.paddr[31:0]  = userApbTransaction.paddr[31:0];
      uart_vifApbMaster.pwdata[31:0] = userApbTransaction.pwdata[31:0];
      uart_vifApbMaster.pstrb[3:0]   = userApbTransaction.pstrb[3:0];
      //Hold one cycle before jumping to ACCESS phase of APB protocol
      repeat (1) @ (posedge uart_vifApbMaster.pclk); 
      //ACCESS state of APB protocol
      uart_vifApbMaster.penable = 1'b1;
      //Store read data if this is a read transaction
      if (~uart_vifApbMaster.pwrite && uart_vifApbMaster.pready) begin
         userApbTransaction.prdata[31:0] = uart_vifApbMaster.prdata[31:0];
      end
      //Store pslverr
      userApbTransaction.pslverr = uart_vifApbMaster.pslverr;
      //ENABLE phase is hold in one cycle
      repeat (1) @ (posedge uart_vifApbMaster.pclk);
      //Release psel and penable
      uart_vifApbMaster.psel    = 1'b0;
      uart_vifApbMaster.penable = 1'b0;
    end
    else begin
      uart_vifApbMaster.psel    = 1'b0;
      uart_vifApbMaster.penable = 1'b0;
    end
  endtask: convert_seq2apb

endclass