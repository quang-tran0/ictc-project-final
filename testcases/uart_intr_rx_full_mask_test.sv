// VPlan 7.06: RX FIFO full interrupt masked
class uart_intr_rx_full_mask_test extends uart_base_test;
    `uvm_component_utils(uart_intr_rx_full_mask_test)

    function new(string name = "uart_intr_rx_full_mask_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        byte unsigned q[$];
        minimum_rx = 16;
        configure_uart();
        for (int i = 0; i < 16; i++) q.push_back(8'(i));
        send_rx(q);
        read_expect('h014, 4, 4);
        bus_write('h010, 0);
        check_irq(0);
        drain_rx(16);
    endtask
endclass
