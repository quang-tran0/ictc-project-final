// VPlan 3.15: TX divisor=1, OSM13 timing boundary
class uart_baud_divisor_min_test extends uart_base_test;
    `uvm_component_utils(uart_baud_divisor_min_test)

    function new(string name = "uart_baud_divisor_min_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 1;
        configure_uart(8, UART_PARITY_NONE, 1, 13, 1);
        read_expect('h004, 1, 'hff);
        read_expect('h008, 0, 'hff);
        transmit('{8'h55});
        wait_tx(1);
    endtask
endclass
