class uart_rx_parity_bug_test extends uart_base_test;
    `uvm_component_utils(uart_rx_parity_bug_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart(8,1,1,0,4);
        check_reg('hc,'h3b); write_reg('h10,'h10);
        send_rx(0,1); // Eight zero data bits, deliberately incorrect parity=1.
        read_rx(1);
        check_reg('h14,'h10,'h10,"PARITY_SET"); check_irq(1,"Injected even parity error");
        write_reg('h14,0); check_reg('h14,'h10,'h10,"PARITY_WRITE_ZERO");
        write_reg('h14,'h10); check_reg('h14,0,'h10,"PARITY_W1C");
        check_irq(0,"Parity clear"); require_counts(0,1);
    endtask
endclass
