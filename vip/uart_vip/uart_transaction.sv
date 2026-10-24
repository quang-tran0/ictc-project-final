typedef enum bit {UART_TX, UART_RX} uart_direction_e;
class uart_transaction extends uvm_sequence_item;
    rand bit [7:0] data;
    rand uart_direction_e direction = UART_TX;
    rand bit inject_parity_error = 0;
    rand bit inject_stop_error = 0;
    rand int unsigned stop_error_index = 0;
    int unsigned data_width, stop_bits, oversampling;
    int unsigned parity_mode;
    realtime started_at, period;

    constraint normal_frame_c {
        soft direction == UART_TX;
        soft inject_parity_error == 0;
        soft inject_stop_error == 0;
        soft stop_error_index == 0;
        if (data_width inside {[5:8]})
            data < (1 << data_width);
        if (stop_bits inside {[1:2]})
            stop_error_index < stop_bits;
    }

    `uvm_object_utils_begin(uart_transaction)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_enum(uart_direction_e, direction, UVM_ALL_ON)
    `uvm_field_int(inject_parity_error, UVM_ALL_ON)
    `uvm_field_int(inject_stop_error, UVM_ALL_ON)
    `uvm_field_int(stop_error_index, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "uart_transaction");
        super.new(name);
    endfunction
endclass
