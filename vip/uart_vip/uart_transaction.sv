`ifndef UART_TRANSACTION__SV
`define UART_TRANSACTION__SV

class uart_transaction extends uvm_sequence_item;
    `uvm_object_utils(uart_transaction)

    typedef enum bit {
        UART_TX,
        UART_RX
    } uart_direction_e;

    rand bit [7:0] data;
    rand uart_direction_e direction;
    rand bit [7:0] inject_parity_error;
    rand bit [7:0] inject_stop_error;
    rand int unsigned stop_error_index;

    constraint c_error_index {
        stop_error_index inside {[0:1]};
    }

    `uvm_object_utils_begin(uart_transaction)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_enum(uart_direction_e, direction, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(inject_parity_error, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(inject_stop_error, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(stop_error_index, UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "uart_transaction");
        super.new(name);
    endfunction
endclass

`endif