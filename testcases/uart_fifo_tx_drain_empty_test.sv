// VPlan 6.05: TX FIFO empty transition
class uart_fifo_tx_drain_empty_test extends uart_base_test;
    `uvm_component_utils(uart_fifo_tx_drain_empty_test)

    function new(string name = "uart_fifo_tx_drain_empty_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 1;
        configure_uart();
        transmit('{8'h55});
        wait_tx(1);
        read_expect('h014, 2, 3, "TX drained");
        expect_value(env.scoreboard.tx_nonempty_cycles > 0, 1, 1, "Nonempty state was observed");
    endtask
endclass
