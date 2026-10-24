// VPlan 4.18: TX 6E1 / 13×
class uart_tx_w6_even_s1_osm13_test extends uart_base_test;
    `uvm_component_utils(uart_tx_w6_even_s1_osm13_test)

    function new(string name = "uart_tx_w6_even_s1_osm13_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 1;
        configure_uart(6, UART_PARITY_EVEN, 1, 13, 67);
        transmit('{8'h15});
        wait_tx(1);

        random_serial_frames(0);
    endtask
endclass
