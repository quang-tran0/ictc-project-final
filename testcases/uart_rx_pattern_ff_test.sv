// VPlan 5.50: RX all-one pattern
class uart_rx_pattern_ff_test extends uart_base_test;
    `uvm_component_utils(uart_rx_pattern_ff_test)

    function new(string name = "uart_rx_pattern_ff_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_rx = 1;
        configure_uart();
        send_rx('{8'hff});
        drain_rx(1);
    endtask
endclass
