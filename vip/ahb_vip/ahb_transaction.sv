class ahb_transaction extends uvm_sequence_item;
    typedef enum bit {READ, WRITE} xact_type_e;
    typedef enum bit [2:0] {AHB_SINGLE=0, AHB_INCR=1} burst_type_e;
    typedef enum bit [1:0] {AHB_IDLE=0, AHB_BUSY=1, AHB_NONSEQ=2, AHB_SEQ=3} htrans_type_e;
    rand bit [9:0] addr;
    rand bit [31:0] data;
    rand xact_type_e kind = READ;
    rand burst_type_e burst = AHB_SINGLE;
    htrans_type_e htrans = AHB_NONSEQ;
    bit selected = 1;
    logic [31:0] rdata;
    logic resp;
    int unsigned wait_cycles;
    constraint legal {addr[1:0] == 0;}
    `uvm_object_utils_begin(ahb_transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_enum(xact_type_e, kind, UVM_ALL_ON)
        `uvm_field_enum(burst_type_e, burst, UVM_ALL_ON)
        `uvm_field_enum(htrans_type_e, htrans, UVM_ALL_ON)
        `uvm_field_int(selected, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(resp, UVM_ALL_ON)
    `uvm_object_utils_end
    function new(string name="ahb_transaction"); super.new(name); endfunction
endclass
