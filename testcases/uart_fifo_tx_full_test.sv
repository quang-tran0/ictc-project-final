// VPlan 6.02: TX FIFO reaches full
class uart_fifo_tx_full_test extends uart_base_test;
    `uvm_component_utils(uart_fifo_tx_full_test)

    function new(string name = "uart_fifo_tx_full_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        int count;
        fill_tx();
        read_expect('h014, 1, 1, "TX FIFO full");
        count = env.scoreboard.tx_expected.size();
        minimum_tx = count;
        wait_tx(count);
        read_expect('h014, 2, 3, "TX FIFO empty after drain");
    endtask
endclass
