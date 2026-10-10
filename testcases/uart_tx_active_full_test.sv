class uart_tx_active_full_test extends uart_base_test;
    `uvm_component_utils(uart_tx_active_full_test)
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart(8,0,1,0,256); // All writes finish well within the first start bit.
        for(int i=0; i<17; i++) write_reg('h18,i);
        check_reg('h14,1,3,"TX_ACTIVE_FULL");
        repeat(3) reject_full_tx('hee);
        wait_tx(17); check_reg('h14,2,3);
        check_value(env.scoreboard.tx_dropped==3,"TX_ACTIVE_DROP_COUNT","Expected 3 rejected writes");
        require_counts(17,0);
    endtask
endclass
