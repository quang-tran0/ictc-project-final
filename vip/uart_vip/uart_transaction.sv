class uart_transaction extends uvm_sequence_item;
    typedef enum bit {UART_TX, UART_RX} uart_direction_e; // Directions relative to DUT.
    rand bit [7:0] data;
    uart_direction_e direction;
    bit inject_parity_error = 0;
    bit parity_error, stop_error;
    int unsigned data_width, parity_mode, stop_bits, divisor;
    bit osm_sel;
    time start_time;
    `uvm_object_utils_begin(uart_transaction)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_enum(uart_direction_e, direction, UVM_ALL_ON)
        `uvm_field_int(inject_parity_error, UVM_ALL_ON)
        `uvm_field_int(parity_error, UVM_ALL_ON)
        `uvm_field_int(stop_error, UVM_ALL_ON)
    `uvm_object_utils_end
    function new(string name="uart_transaction"); super.new(name); endfunction
endclass
