typedef enum bit [1:0] {
UART_PARITY_NONE, UART_PARITY_EVEN, UART_PARITY_ODD
} uart_parity_e;

class uart_configuration extends uvm_object;
    `uvm_object_utils(uart_configuration)
    virtual uart_if vif;
    logic reset_n = 1'b1;
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    uart_parity_e parity_mode = UART_PARITY_NONE;
    int unsigned data_width = 8;
    int unsigned num_of_stop_bit = 1;
    int unsigned baud_rate = 115200;
    int unsigned oversampling = 16;
    realtime programmed_period = 0;
    bit monitor_enable = 0;

    function new(string name = "uart_configuration");
        super.new(name);
    endfunction

    function bit is_valid();
        return vif != null && data_width inside {[5:8]} &&
        num_of_stop_bit inside {[1:2]} && baud_rate > 0 &&
        programmed_period >= 0 && bit_period() >= 4ps &&
        is_active inside {UVM_ACTIVE, UVM_PASSIVE} &&
        parity_mode inside {UART_PARITY_NONE, UART_PARITY_EVEN, UART_PARITY_ODD};
    endfunction

    function realtime bit_period();
        realtime period;
        period = programmed_period > 0 ? programmed_period : 1s / real'(baud_rate);
        // Resolve once to the simulator precision. Repeated symbol delays and
        // absolute monitor deadlines must use the same representable period.
        return real'(longint'(period / 1ps)) * 1ps;
    endfunction

    function realtime frame_period();
        return bit_period() * (1 + data_width + num_of_stop_bit +
            (parity_mode != UART_PARITY_NONE));
    endfunction
endclass
