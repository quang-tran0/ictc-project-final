// VPlan 7.01: TX FIFO full interrupt enabled
class uart_intr_tx_full_enable_test extends uart_base_test;
    `uvm_component_utils(uart_intr_tx_full_enable_test)

    function new(string name = "uart_intr_tx_full_enable_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        int n;
        fill_tx();
        n = env.scoreboard.tx_expected.size();
        minimum_tx = n;
        bus_write('h010, 1);
        check_irq(1);
        wait_status(1, 0);
        check_irq(0);
        wait_tx(n);
    endtask
endclass
