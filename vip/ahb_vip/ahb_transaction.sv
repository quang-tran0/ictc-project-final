`ifndef AHB_TRANSACTION__SV
`define AHB_TRANSACTION__SV

class ahb_transaction extends uvm_sequence_item;
    `uvm_object_utils(ahb_transaction)

    typedef enum bit {
        READ=0,
        WRITE=1
    } xact_type_e;

    typedef enum bit [2:0] {
        AHB_SINGLE=3'b000,
        AHB_INCR=3'b001,
        AHB_WRAP4=3'b010,
        AHB_INCR4=3'b011,
        AHB_WRAP8=3'b100,
        AHB_INCR8=3'b101,
        AHB_WRAP16=3'b110,
        AHB_INCR16=3'b111
    } burst_type_e;

    typedef enum bit [1:0] {
        AHB_IDLE=2'b00,
        AHB_BUSY=2'b01,
        AHB_NONSEQ=2'b10,
        AHB_SEQ=2'b11
    } htrans_type_e;

    rand bit [31:0] addr;
    rand bit [31:0] data;
    xact_type_e     type;
    burst_type_e    burst;
    htrans_type_e   htrans;

    function new(string name = "ahb_transaction");
        super.new(name);
    endfunction
endclass

`endif