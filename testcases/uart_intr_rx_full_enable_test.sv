// VPlan 7.05: RX FIFO full interrupt enabled
class uart_intr_rx_full_enable_test extends uart_base_test;
    `uvm_component_utils(uart_intr_rx_full_enable_test)

    function new(string name = "uart_intr_rx_full_enable_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        byte unsigned q[$];
        logic [31:0] d;
        minimum_rx = 16;
        configure_uart();
        for (int i = 0; i < 16; i++) q.push_back(8'(i));
        send_rx(q);
        read_expect('h014, 4, 4);
        bus_write('h010, 4);
        check_irq(1);
        bus_read('h01c, d);
        read_expect('h014, 0, 4);
        check_irq(0);
        drain_rx(15);
    endtask
endclass
