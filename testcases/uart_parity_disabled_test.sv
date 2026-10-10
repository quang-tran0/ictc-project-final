class uart_parity_disabled_test extends uart_base_test;
    `uvm_component_utils(uart_parity_disabled_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart(8,0,1,0,4); write_reg('h10,'h10);
        send_rx('hff,1); read_rx(1); send_rx('h00,1); read_rx(1);
        check_reg('h14,0,'h10,"NO_PARITY_STATUS"); check_irq(0,"No parity checking when PEN=0");
        require_counts(0,2);
    endtask
endclass
