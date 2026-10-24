// VPlan 3.10: Baud timing 9600 bps / 13×
class uart_baud_9600_osm13_test extends uart_base_test;
    `uvm_component_utils(uart_baud_9600_osm13_test)

    function new(string name = "uart_baud_9600_osm13_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 1;
        configure_uart(8, UART_PARITY_NONE, 1, 13, 801);
        read_expect('h004, 'h21, 'hff);
        read_expect('h008, 3, 'hff);
        transmit('{8'h55});
        wait_tx(1);
    endtask
endclass
