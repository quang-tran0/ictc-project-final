`ifndef AHB_TRANSACTION__SV
`define AHB_TRANSACTION__SV

class ahb_transaction extends uvm_sequence_item;
    `uvm_object_utils(ahb_transaction)

    typedef enum bit {
        READ=0,
        WRITE=1
    } xact_type_e;

    typedef enum bit [2:0] {
        SIZE_8BIT=3'b000,
        SIZE_16BIT=3'b001,
        SIZE_32BIT=3'b010,
        SIZE_64BIT=3'b011,
        SIZE_128BIT=3'b100,
        SIZE_256BIT=3'b101,
        SIZE_512BIT=3'b110,
        SIZE_1024BIT=3'b111
    } xfer_size_e;

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

    rand bit [31:0] addr;
    rand bit [31:0] data;
    xact_type_e     xact_type;
    xfer_size_e     xfer_size;
    burst_type_e    burst_type;
    rand bit [3:0]  prot;
    bit             lock;

    `uvm_object_utils_begin(ahb_transaction)
        `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_enum(xact_type_e, xact_type, UVM_ALL_ON | UVM_HEX)
        `uvm_field_enum(xfer_size_e, xfer_size, UVM_ALL_ON | UVM_HEX)
        `uvm_field_enum(burst_type_e, burst_type, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(prot, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(lock, UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "ahb_transaction");
        super.new(name);
    endfunction
endclass

`endif