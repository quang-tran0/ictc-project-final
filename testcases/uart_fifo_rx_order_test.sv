// VPlan 6.09: RX FIFO ordering after ordinary-gap accumulation
class uart_fifo_rx_order_test extends uart_base_test;
    `uvm_component_utils(uart_fifo_rx_order_test)

    function new(string name = "uart_fifo_rx_order_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_rx = 4;
        configure_uart();
        send_rx('{8'h13, 8'h37, 8'hac, 8'he5}, 0, 1);
        drain_rx(4);
    endtask
endclass
