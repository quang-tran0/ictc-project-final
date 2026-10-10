class uart_smoke_test extends uart_base_test;
    `uvm_component_utils(uart_smoke_test)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task scenario();
        check_reg('h00, 0);
        check_reg('h0c, 3);
        check_reg('h14, 'h0a);
        configure_uart(8, 0, 1, 0, 4);
        write_reg('h18, 'h55);
        write_reg('h18, 'ha6);
        wait_tx(2);
        send_rx('h96);
        read_rx(1);
        require_counts(2, 1);
    endtask
endclass
