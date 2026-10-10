class uart_irq_rx_empty_test extends uart_base_test;
    `uvm_component_utils(uart_irq_rx_empty_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart(); write_reg('h10,8); check_irq(1,"RX empty");
        send_rx('h59); cycles(); check_irq(0,"RX received");
        read_rx(1); check_irq(1,"RX drained"); write_reg('h10,0); check_irq(0,"RX empty mask");
        require_counts(0,1);
    endtask
endclass
