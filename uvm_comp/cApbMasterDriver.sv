//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: APB Driver
// - Convert the APB packet to APB transaction
// - Drive the APB signals
//Author:  Nguyen Hung Quan, Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet
//Page:    VLSI Technology
//Fix log:
// - All APB signals are driven with non-blocking assignments at the APB clock edge,
//   so the DUT never samples a value that changes in the same time step (race free).
// - The ACCESS phase waits for pready (with a timeout) instead of lasting one cycle.
// - prdata and pslverr are sampled on the clock edge that ends the ACCESS phase,
//   that is, the values that were valid during the transfer.
// - A reset in the middle of a transfer abandons the item and returns the sequencer handshake.
//--------------------------------------
class cApbMasterDriver extends uvm_driver #(cApbTransaction);
  //1. Declare the virtual interface
  virtual ifApbMaster uart_vifApbMaster;
  cApbTransaction ApbPacket;
  //True between get_next_item and item_done
  bit itemInFlight;
  //2. Register to the factory
  `uvm_component_utils(cApbMasterDriver)
  //3. Class constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new
  //4. Build phase: get the virtual interface, the fatal is triggered if it is missing
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual interface ifApbMaster)::get(.cntxt(this),
          .inst_name(""),
          .field_name("vifApbMaster"),
          .value(uart_vifApbMaster))) begin
       `uvm_fatal("NON-APBIF", {"A virtual interface must be set for: ", get_full_name(), ".uart_vifApbMaster"})
     end
     `uvm_info(get_full_name(), "Build phase completed.", UVM_LOW)
  endfunction
  //5. Run phase
  // Repeat forever: wait for reset release, drive items until the next reset, then idle the bus
  virtual task run_phase (uvm_phase phase);
    idle_bus();
    forever begin
      if (uart_vifApbMaster.preset_n !== 1'b1) begin
        @ (posedge uart_vifApbMaster.preset_n);
      end
      fork : drive_or_reset
        get_seq_and_drive ();
        @ (negedge uart_vifApbMaster.preset_n);
      join_any
      disable drive_or_reset;
      //Reset interrupted a transfer: return the handshake so the sequencer does not hang
      if (itemInFlight) begin
        seq_item_port.item_done();
        itemInFlight = 1'b0;
        `uvm_info(get_type_name(), "Reset aborted the APB transfer in flight", UVM_MEDIUM)
      end
      idle_bus();
    end
  endtask
  //
  //Methods
  //
  //Release the bus: no select, no enable
  virtual function void idle_bus();
    uart_vifApbMaster.psel    <= 1'b0;
    uart_vifApbMaster.penable <= 1'b0;
  endfunction: idle_bus
  //Get an item from the sequencer and drive it, until the task is killed by reset
  virtual task get_seq_and_drive();
    forever begin
      seq_item_port.get_next_item(ApbPacket);
      itemInFlight = 1'b1;
      convert_seq2apb(ApbPacket);
      seq_item_port.item_done();
      itemInFlight = 1'b0;
    end
  endtask: get_seq_and_drive
  //Drive one APB transfer
  virtual task convert_seq2apb (cApbTransaction userApbTransaction);
    int waitCnt;
    //Note:
    // 1. apbSeqEn of cApbTransaction is used as a valid flag of an APB packet
    // 2. apbConEn = 1 starts the SETUP phase right after the previous transfer (back-to-back)
    if (!userApbTransaction.apbSeqEn) begin
      idle_bus();
      return;
    end
    //One idle cycle before the transfer, unless it is back-to-back with the previous one
    if (userApbTransaction.apbConEn == 0) begin
      idle_bus();
      @ (posedge uart_vifApbMaster.pclk);
    end
    //SETUP phase: present the address, control and data signals
    uart_vifApbMaster.psel         <= 1'b1;
    uart_vifApbMaster.penable      <= 1'b0;
    uart_vifApbMaster.pwrite       <= userApbTransaction.pwrite;
    uart_vifApbMaster.paddr[31:0]  <= userApbTransaction.paddr[31:0];
    uart_vifApbMaster.pwdata[31:0] <= userApbTransaction.pwdata[31:0];
    uart_vifApbMaster.pstrb[3:0]   <= userApbTransaction.pstrb[3:0];
    //End of the SETUP cycle
    @ (posedge uart_vifApbMaster.pclk);
    //ACCESS phase: assert penable and hold until the slave is ready
    uart_vifApbMaster.penable <= 1'b1;
    waitCnt = 0;
    forever begin
      @ (posedge uart_vifApbMaster.pclk);
      //At this edge the signals still hold the values of the ACCESS cycle
      if (uart_vifApbMaster.pready === 1'b1) begin
        userApbTransaction.pready = 1;
        if (~userApbTransaction.pwrite) begin
          userApbTransaction.prdata[31:0] = uart_vifApbMaster.prdata[31:0];
        end
        userApbTransaction.pslverr = uart_vifApbMaster.pslverr;
        break;
      end
      waitCnt++;
      if (waitCnt >= cApbTransaction::APB_TRANSACTION_TIMEOUT) begin
        userApbTransaction.pready = 0;
        `uvm_error("APB TIMEOUT", $sformatf("pready is not asserted within %0d cycles, paddr = %8h", waitCnt, userApbTransaction.paddr))
        break;
      end
    end
    //End of the transfer: release psel and penable
    //If the next item is back-to-back, its SETUP assignments follow in this time step and override these
    uart_vifApbMaster.psel    <= 1'b0;
    uart_vifApbMaster.penable <= 1'b0;
  endtask: convert_seq2apb

endclass
