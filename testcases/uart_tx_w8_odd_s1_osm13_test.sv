// VPlan 4.46: TX 8O1 / 13×
class uart_tx_w8_odd_s1_osm13_test extends uart_base_test;
    `uvm_component_utils(uart_tx_w8_odd_s1_osm13_test)

    function new(string name = "uart_tx_w8_odd_s1_osm13_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 1;
        configure_uart(8, UART_PARITY_ODD, 1, 13, 67);
        transmit('{8'h55});
        wait_tx(1);

        random_serial_frames(0);
    endtask
endclass
