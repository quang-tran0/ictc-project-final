// VPlan 6.07: RX FIFO becomes full
class uart_fifo_rx_full_test extends uart_base_test;
    `uvm_component_utils(uart_fifo_rx_full_test)

    function new(string name = "uart_fifo_rx_full_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        byte unsigned q[$];
        minimum_rx = 16;
        configure_uart();
        for (int i = 0; i < 16; i++) q.push_back(8'(i + 'h40));
        send_rx(q);
        read_expect('h014, 4, 'h0c, "RX exactly16-byte full");
        drain_rx(16);
    endtask
endclass
