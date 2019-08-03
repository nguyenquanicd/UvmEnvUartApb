//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: Define user macros
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//--------------------------------------
//--------------------------------------
//Write "value" to "address" of a register of UART-TX
//--------------------------------------
`define ApbWriteTX(address,value) \
`uvm_do_on_with(WriteSeq, p_sequencer.coApbMasterAgentTx.coApbMasterSequencer, { \
               WriteSeq.conEn      == 1'b0; \
               WriteSeq.addr[31:0] == address; \
               WriteSeq.data[31:0] == value; \
               WriteSeq.be[3:0]    == 4'b1111; \
               })

//--------------------------------------
//Read "value" from "address" of a register of UART-TX
//--------------------------------------
`define ApbReadTX(address) \
`uvm_do_on_with(ReadSeq, p_sequencer.coApbMasterAgentTx.coApbMasterSequencer, { \
               WriteSeq.conEn      == 1'b0; \
               WriteSeq.addr[31:0] == address; \
               WriteSeq.be[3:0]    == 4'b1111; \
               })

//--------------------------------------
//Write "value" to "address" of a register of UART-RX
//--------------------------------------
`define ApbWriteRX(address,value) \
`uvm_do_on_with(WriteSeq, p_sequencer.coApbMasterAgentRx.coApbMasterSequencer, { \
               WriteSeq.conEn      == 1'b0; \
               WriteSeq.addr[31:0] == address; \
               WriteSeq.data[31:0] == value; \
               WriteSeq.be[3:0]    == 4'b1111; \
               })

//--------------------------------------
//Read "value" from "address" of a register of UART-RX
//--------------------------------------
`define ApbReadRX(address) \
`uvm_do_on_with(ReadSeq, p_sequencer.coApbMasterAgentRx.coApbMasterSequencer, { \
               WriteSeq.conEn      == 1'b0; \
               WriteSeq.addr[31:0] == address; \
               WriteSeq.be[3:0]    == 4'b1111; \
               })
