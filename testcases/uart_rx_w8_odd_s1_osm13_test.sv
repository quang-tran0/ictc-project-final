// VPlan 5.46: RX 8O1 / 13×
class uart_rx_w8_odd_s1_osm13_test extends uart_base_test;
    `uvm_component_utils(uart_rx_w8_odd_s1_osm13_test)

    function new(string name = "uart_rx_w8_odd_s1_osm13_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_rx = 1;
        configure_uart(8, UART_PARITY_ODD, 1, 13, 67);
        send_rx('{8'ha6});
        drain_rx(1);
        read_expect('h014, 0, 'h10, "Valid frame has no parity error");

        random_serial_frames(1);
    endtask
endclass
