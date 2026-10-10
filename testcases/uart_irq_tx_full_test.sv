class uart_irq_tx_full_test extends uart_base_test;
    `uvm_component_utils(uart_irq_tx_full_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart(); write_reg('hc,3); write_reg('h10,1); check_irq(0,"TX not full");
        repeat(17) write_reg('h18,'ha5);
        check_irq(1,"TX full"); write_reg('hc,'h23); wait_tx(17);
        check_irq(0,"TX drain clears full"); require_counts(17,0);
    endtask
endclass
