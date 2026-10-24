// VPlan 7.02: TX FIFO full interrupt masked
class uart_intr_tx_full_mask_test extends uart_base_test;
    `uvm_component_utils(uart_intr_tx_full_mask_test)

    function new(string name = "uart_intr_tx_full_mask_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        int n;
        fill_tx();
        n = env.scoreboard.tx_expected.size();
        minimum_tx = n;
        bus_write('h010, 0);
        read_expect('h014, 1, 1, "Active TX full source");
        check_irq(0);
        wait_tx(n);
    endtask
endclass
