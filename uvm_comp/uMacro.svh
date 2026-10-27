//--------------------------------------
//Project: The UVM environemnt for UART (Universal Asynchronous Receiver Transmitter)
//Function: Define user macros
//Author:  Pham Thanh Tram, Nguyen Sinh Ton, Doan Duc Hoang, Truong Cong Hoang Viet, Nguyen Hung Quan
//Page:    VLSI Technology
//--------------------------------------
//Why no `uvm_do_on_with: it calls randomize(), and in the open-source flow every call starts the z3
//constraint solver (slow, and the solver fails after many calls). Every field is fixed by the macro,
//so the sequence is created, assigned directly and started on the sequencer of the agent.
//--------------------------------------
//Internal: create SEQ (class CLS), fill the fields (STMTS), start it on SQR
`define ApbStartSeq(SEQ, CLS, SQR, STMTS) \
  begin \
    SEQ = CLS::type_id::create(`"SEQ`"); \
    STMTS \
    SEQ.start(SQR, this); \
  end

//--------------------------------------
//Write "value" to "address" of a register of UART-TX / UART-RX
// address - 32-bit write address
// value - 32-bit write value
//--------------------------------------
`define ApbWriteTX(address,value) \
`ApbStartSeq(WriteSeq, cApbMasterWriteSeq, p_sequencer.coApbMasterAgentTx.coApbMasterSequencer, \
  WriteSeq.conEn = 1'b0; WriteSeq.addr = address; WriteSeq.data = value; WriteSeq.be = 4'b1111;)

`define ApbWriteRX(address,value) \
`ApbStartSeq(WriteSeq, cApbMasterWriteSeq, p_sequencer.coApbMasterAgentRx.coApbMasterSequencer, \
  WriteSeq.conEn = 1'b0; WriteSeq.addr = address; WriteSeq.data = value; WriteSeq.be = 4'b1111;)

//--------------------------------------
//Read "address" of UART-TX / UART-RX and compare with "expectedData" on the bits set in "uMask"
//--------------------------------------
`define ApbReadTX(address,expectedData,uMask) \
`ApbStartSeq(ReadSeq, cApbMasterReadSeq, p_sequencer.coApbMasterAgentTx.coApbMasterSequencer, \
  ReadSeq.conEn = 1'b0; ReadSeq.addr = address; ReadSeq.expectedReadData = expectedData; ReadSeq.mask = uMask;)

`define ApbReadRX(address,expectedData,uMask) \
`ApbStartSeq(ReadSeq, cApbMasterReadSeq, p_sequencer.coApbMasterAgentRx.coApbMasterSequencer, \
  ReadSeq.conEn = 1'b0; ReadSeq.addr = address; ReadSeq.expectedReadData = expectedData; ReadSeq.mask = uMask;)

//--------------------------------------
//Write a random 8-bit value to "address" of UART-TX
//--------------------------------------
`define ApbWriteRandTX(address) \
`ApbStartSeq(WriteSeq, cApbMasterWriteSeq, p_sequencer.coApbMasterAgentTx.coApbMasterSequencer, \
  WriteSeq.conEn = 1'b0; WriteSeq.addr = address; WriteSeq.data = $urandom_range(32'h000000FF, 32'h00000000); WriteSeq.be = 4'b1111;)

//--------------------------------------
//Read "address" of UART-RX without comparison (the value is in ReadSeqWoCmpr.coApbTransaction.prdata)
//--------------------------------------
`define ApbReadWoCmprRX(address) \
`ApbStartSeq(ReadSeqWoCmpr, cApbMasterWriteSeqNotCmpr, p_sequencer.coApbMasterAgentRx.coApbMasterSequencer, \
  ReadSeqWoCmpr.conEn = 1'b0; ReadSeqWoCmpr.addr = address;)
