class uart_configuration extends uvm_object;
    typedef enum int {UART_PARITY_NONE, UART_PARITY_EVEN, UART_PARITY_ODD} uart_parity_e;
    `uvm_object_utils(uart_configuration)
    virtual uart_if vif;
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    int unsigned data_width = 8;
    uart_parity_e parity = UART_PARITY_NONE;
    int unsigned num_of_stop_bits = 1;
    bit osm_sel = 0;
    int unsigned divisor = 4;
    time clock_period = 10ns;
    function new(string name="uart_configuration"); super.new(name); endfunction
    function time bit_period(); return clock_period * divisor * (osm_sel ? 13 : 16); endfunction
    function time frame_period();
        return bit_period() * (1 + data_width + (parity != UART_PARITY_NONE) + num_of_stop_bits);
    endfunction
    function bit is_valid();
        return vif != null && data_width inside {[5:8]} && num_of_stop_bits inside {[1:2]} &&
               divisor inside {[1:65535]} && clock_period > 0 &&
               parity inside {UART_PARITY_NONE, UART_PARITY_EVEN, UART_PARITY_ODD};
    endfunction
endclass
