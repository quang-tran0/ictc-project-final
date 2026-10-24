// VPlan 6.03: TX write while full ignored
class uart_fifo_tx_overflow_ignore_test extends uart_base_test;
    `uvm_component_utils(uart_fifo_tx_overflow_ignore_test)

    function new(string name = "uart_fifo_tx_overflow_ignore_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        int count, rejected;
        fill_tx();
        count = env.scoreboard.tx_expected.size();
        minimum_tx = count + 1;
        rejected = env.scoreboard.rejected_tx;
        bus_write('h018, 'he1);
        bus_write('h018, 'he2);
        expect_value(env.scoreboard.rejected_tx, rejected + 2, '1, "Two full-state writes rejected");
        wait_tx(count);
        transmit('{8'h3c});
        wait_tx(count + 1);
    endtask
endclass
