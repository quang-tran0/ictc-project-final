// Directions are relative to the VIP: TX -> DUT uart_rxd; RX <- DUT uart_txd.
typedef enum bit {UART_TX, UART_RX} uart_direction_e;

class uart_transaction extends uvm_sequence_item;

    rand logic [7:0]         data;
    rand uart_direction_e  direction;
    rand bit               inject_parity_error;
    rand bit               inject_stop_error;
    rand int unsigned      stop_error_index;

    bit completed;
    bit parity_error; // Observed errors; injection fields describe requests only.
    bit stop_error;
    bit baud_error;

    constraint default_traffic_c {
        soft direction == UART_TX;
        soft inject_parity_error == 0;
        soft inject_stop_error == 0;
        stop_error_index inside {[0:1]};
    }

    `uvm_object_utils_begin(uart_transaction)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_enum(uart_direction_e, direction, UVM_ALL_ON)
        `uvm_field_int(inject_parity_error, UVM_ALL_ON)
        `uvm_field_int(inject_stop_error, UVM_ALL_ON)
        `uvm_field_int(stop_error_index, UVM_ALL_ON)
        `uvm_field_int(completed, UVM_ALL_ON)
        `uvm_field_int(parity_error, UVM_ALL_ON)
        `uvm_field_int(stop_error, UVM_ALL_ON)
        `uvm_field_int(baud_error, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "uart_transaction");
        super.new(name);
    endfunction
endclass
