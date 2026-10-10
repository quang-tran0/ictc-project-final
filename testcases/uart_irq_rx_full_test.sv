class uart_irq_rx_full_test extends uart_base_test;
    `uvm_component_utils(uart_irq_rx_full_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart(); write_reg('h10,4); check_irq(0,"RX not full");
        repeat(16) send_rx('h36);
        check_irq(1,"RX full"); read_rx(1); check_irq(0,"RX full clears on read");
        read_rx(15); require_counts(0,16);
    endtask
endclass
