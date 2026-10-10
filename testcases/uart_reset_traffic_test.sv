class uart_reset_traffic_test extends uart_base_test;
    `uvm_component_utils(uart_reset_traffic_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart(); write_reg('h18,'h55); write_reg('h18,'haa);
        #(uart_cfg.bit_period()*3); reset_dut();
        check_reg('hc,3); check_reg('h14,'ha); check_irq(0,"Reset clears interrupt");
        configure_uart(); write_reg('h18,'h96); wait_tx(1);
        fork
            send_rx('h55);
            begin #(uart_cfg.bit_period()*3); reset_dut(); end
        join
        check_reg('h14,'ha);
        configure_uart(); send_rx('h69); read_rx(1); require_counts(1,1);
    endtask
endclass
