class uart_rx_format_test extends uart_base_test;
    `uvm_component_utils(uart_rx_format_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        for(int osm=0; osm<2; osm++)
          for(int width=5; width<=8; width++)
            for(int parity=0; parity<3; parity++)
              for(int stops=1; stops<=2; stops++) begin
                configure_uart(width,parity,stops,osm,4);
                send_rx('h00); send_rx('hff); send_rx('h55); send_rx('haa);
                read_rx(4); check_reg('h14,0,'h10,"VALID_PARITY_STATUS");
              end
        require_counts(0,192);
    endtask
endclass
