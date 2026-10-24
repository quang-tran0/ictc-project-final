// VPlan 6.10: RX FIFO drain from full
class uart_fifo_rx_full_to_empty_test extends uart_base_test;
    `uvm_component_utils(uart_fifo_rx_full_to_empty_test)

    function new(string name = "uart_fifo_rx_full_to_empty_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        byte unsigned q[$];
        logic [31:0] d;
        minimum_rx = 16;
        configure_uart();
        for (int i = 0; i < 16; i++) q.push_back(8'(i^'he0));
        send_rx(q);
        read_expect('h014, 4, 'h0c, "Start at full");
        bus_read('h01c, d);
        read_expect('h014, 0, 'h0c, "Full clears with15 bytes left");
        repeat (14) bus_read('h01c, d);
        read_expect('h014, 0, 'h0c, "One byte left is neither full nor empty");
        bus_read('h01c, d);
        read_expect('h014, 8, 'h0c, "Final pop sets empty");
    endtask
endclass
