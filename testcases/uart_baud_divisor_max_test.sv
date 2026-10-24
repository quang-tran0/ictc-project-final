// VPlan 3.16: TX divisor=65535, OSM16 timing boundary
class uart_baud_divisor_max_test extends uart_base_test;
    `uvm_component_utils(uart_baud_divisor_max_test)

    function new(string name = "uart_baud_divisor_max_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 1;
        configure_uart(8, UART_PARITY_NONE, 1, 16, 65535);
        read_expect('h004, 'hff, 'hff);
        read_expect('h008, 'hff, 'hff);
        transmit('{8'h55});
        wait_tx(1);
    endtask
endclass
