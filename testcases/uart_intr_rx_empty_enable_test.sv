// VPlan 7.07: RX FIFO empty interrupt enabled
class uart_intr_rx_empty_enable_test extends uart_base_test;
    `uvm_component_utils(uart_intr_rx_empty_enable_test)

    function new(string name = "uart_intr_rx_empty_enable_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_rx = 1;
        bus_write('h010, 8);
        check_irq(1);
        configure_uart();
        send_rx('{8'ha6});
        read_expect('h014, 0, 8);
        check_irq(0);
        drain_rx(1);
        check_irq(1);
    endtask
endclass
