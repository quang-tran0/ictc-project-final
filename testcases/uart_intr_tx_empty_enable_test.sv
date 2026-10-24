// VPlan 7.03: TX FIFO empty interrupt enabled
class uart_intr_tx_empty_enable_test extends uart_base_test;
    `uvm_component_utils(uart_intr_tx_empty_enable_test)

    function new(string name = "uart_intr_tx_empty_enable_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        int n;
        read_expect('h014, 2, 2);
        bus_write('h010, 2);
        check_irq(1);
        fill_tx();
        n = env.scoreboard.tx_expected.size();
        minimum_tx = n;
        check_irq(0);
        wait_tx(n);
        check_irq(1);
    endtask
endclass
