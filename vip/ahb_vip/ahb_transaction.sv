class ahb_transaction extends uvm_sequence_item;
    `uvm_object_utils(ahb_transaction)

    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit [1:0]  size;
    rand bit [1:0]  burst;
    rand bit        write;
endclass