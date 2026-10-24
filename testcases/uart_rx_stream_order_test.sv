// VPlan 5.51: RX minimum-gap stream, 8N1 / OSM13
class uart_rx_stream_order_test extends uart_base_test;
    `uvm_component_utils(uart_rx_stream_order_test)

    function new(string name = "uart_rx_stream_order_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_rx = 4;
        configure_uart(8, UART_PARITY_NONE, 1, 13, 67);
        send_rx('{8'h21, 8'h43, 8'h65, 8'h87}, 0, 0);
        drain_rx(4);
        read_expect('h014, 0, 'h10, "Valid minimum-gap stream has no parity error");
    endtask
endclass
