// VPlan 5.49: RX all-zero pattern
class uart_rx_pattern_zero_test extends uart_base_test;
    `uvm_component_utils(uart_rx_pattern_zero_test)

    function new(string name = "uart_rx_pattern_zero_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_rx = 1;
        configure_uart();
        send_rx('{8'h00});
        drain_rx(1);
    endtask
endclass
