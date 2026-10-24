// VPlan 5.31: RX 7E2 / 16×
class uart_rx_w7_even_s2_osm16_test extends uart_base_test;
    `uvm_component_utils(uart_rx_w7_even_s2_osm16_test)

    function new(string name = "uart_rx_w7_even_s2_osm16_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_rx = 1;
        configure_uart(7, UART_PARITY_EVEN, 2, 16, 54);
        send_rx('{8'h26});
        drain_rx(1);
        read_expect('h014, 0, 'h10, "Valid frame has no parity error");

        random_serial_frames(1);
    endtask
endclass
