typedef enum bit [1:0] {
  UART_PARITY_NONE,
  UART_PARITY_EVEN,
  UART_PARITY_ODD
} uart_parity_e;

class uart_configuration extends uvm_object;
    uart_parity_e parity_mode = UART_PARITY_NONE;
    int unsigned data_width = 8;
    int unsigned num_of_stop_bit = 1;
    int unsigned baud_rate = 115200;
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    virtual uart_if vif;

    `uvm_object_utils_begin(uart_configuration)
        `uvm_field_enum(uart_parity_e, parity_mode, UVM_ALL_ON)
        `uvm_field_int(data_width, UVM_ALL_ON)
        `uvm_field_int(num_of_stop_bit, UVM_ALL_ON)
        `uvm_field_int(baud_rate, UVM_ALL_ON)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "uart_configuration");
        super.new(name);
    endfunction

    function bit is_valid();
        return 
            (parity_mode inside {
                UART_PARITY_NONE, UART_PARITY_EVEN, UART_PARITY_ODD
            }) &&
            (data_width inside {[5:8]}) &&
            (num_of_stop_bit inside {[1:2]}) &&
            (baud_rate > 0);
    endfunction

    function realtime bit_period();
        return 1s / baud_rate;
    endfunction
endclass
