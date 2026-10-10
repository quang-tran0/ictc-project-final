class uart_irq_tx_empty_test extends uart_base_test;
    `uvm_component_utils(uart_irq_tx_empty_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart(); write_reg('hc,3); write_reg('h10,2); cycles();
        check_irq(1,"TX empty interrupt"); write_reg('h18,'h55); write_reg('h18,'haa); cycles();
        check_irq(0,"TX nonempty clears interrupt");
        write_reg('hc,'h23); wait_tx(2); check_irq(1,"TX drained interrupt");
        write_reg('h10,0); check_irq(0,"TX empty mask"); require_counts(2,0);
    endtask
endclass
