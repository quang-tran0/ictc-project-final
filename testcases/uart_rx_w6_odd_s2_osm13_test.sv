// VPlan 5.24: RX 6O2 / 13×
class uart_rx_w6_odd_s2_osm13_test extends uart_base_test;
    `uvm_component_utils(uart_rx_w6_odd_s2_osm13_test)

    function new(string name = "uart_rx_w6_odd_s2_osm13_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_rx = 1;
        configure_uart(6, UART_PARITY_ODD, 2, 13, 67);
        send_rx('{8'h26});
        drain_rx(1);
        read_expect('h014, 0, 'h10, "Valid frame has no parity error");

        random_serial_frames(1);
    endtask
endclass
