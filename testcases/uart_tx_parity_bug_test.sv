class uart_tx_parity_bug_test extends uart_base_test;
    `uvm_component_utils(uart_tx_parity_bug_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart(8,1,1,0,4); // 8E1, 16x, bit time 640 ns.
        check_reg('hc,'h3b);
        write_reg('h18,0); wait_tx(1);
        write_reg('h18,1); wait_tx(2);
        require_counts(2,0);
    endtask
endclass
