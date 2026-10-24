// VPlan 4.50: TX all-one data pattern
class uart_tx_pattern_ff_test extends uart_base_test;
    `uvm_component_utils(uart_tx_pattern_ff_test)

    function new(string name = "uart_tx_pattern_ff_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 1;
        configure_uart();
        transmit('{8'hff});
        wait_tx(1);
    endtask
endclass
