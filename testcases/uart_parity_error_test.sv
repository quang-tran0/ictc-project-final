class uart_parity_error_test extends uart_base_test;
    `uvm_component_utils(uart_parity_error_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        for(int osm=0; osm<2; osm++)
          for(int width=5; width<=8; width++)
            for(int parity=1; parity<=2; parity++) begin
                configure_uart(width,parity,1,osm,4);
                write_reg('h10,'h10); check_irq(0,"Parity initially clear");
                send_rx('h35,1); cycles();
                check_reg('h14,'h10,'h10,"PARITY_SET"); check_irq(1,"Parity error interrupt");
                read_rx(1); send_rx('h56); read_rx(1);
                check_reg('h14,'h10,'h10,"PARITY_STICKY");
                write_reg('h14,0); check_reg('h14,'h10,'h10,"PARITY_WRITE_ZERO");
                write_reg('h10,0); check_irq(0,"Parity mask");
                write_reg('h10,'h10); check_irq(1,"Parity reenable");
                write_reg('h14,'h10); check_reg('h14,0,'h10,"PARITY_W1C"); check_irq(0,"Parity cleared");
            end
        require_counts(0,32);
    endtask
endclass
