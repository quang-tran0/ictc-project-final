`ifndef AHB_TRANSACTION__SV
`define AHB_TRANSACTION__SV
class ahb_transaction extends uvm_sequence_item;
    typedef enum bit {READ = 0, WRITE = 1} xact_type_e;
    typedef enum bit [2:0] {SIZE_32BIT = 3'b010} xfer_size_e;
    typedef enum bit [2:0] {AHB_SINGLE = 3'b000, AHB_INCR = 3'b001} burst_type_e;

    rand bit [9:0] addr;
    bit select = 1;
    bit [1:0] transfer = 2'b10;
    int unsigned wait_cycles;
    rand bit [31:0] data;
    // Write payload only; never interpreted as HRDATA.
    rand xact_type_e xact_type = READ;
    rand xfer_size_e xfer_size = SIZE_32BIT;
    rand burst_type_e burst_type = AHB_SINGLE;
    logic [31:0] rdata;
    // Sampled HRDATA on a completed read.
    logic hresp = 1'bx;
    // Unknown until completion, including reset aborts.
    bit completed = 0;
    // A completed ERROR also sets this to one.

    constraint legal_access_c {
        addr[1:0] == 0;
        soft addr inside {[10'h000:10'h01c]};
        xfer_size == SIZE_32BIT;
        burst_type inside {AHB_SINGLE, AHB_INCR};
    }

    `uvm_object_utils_begin(ahb_transaction)
    `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(select, UVM_ALL_ON)
    `uvm_field_int(transfer, UVM_ALL_ON)
    `uvm_field_int(wait_cycles, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
    `uvm_field_enum(xact_type_e, xact_type, UVM_ALL_ON)
    `uvm_field_enum(xfer_size_e, xfer_size, UVM_ALL_ON)
    `uvm_field_enum(burst_type_e, burst_type, UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(hresp, UVM_ALL_ON)
    `uvm_field_int(completed, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "ahb_transaction");
        super.new(name);
    endfunction
endclass
`endif
