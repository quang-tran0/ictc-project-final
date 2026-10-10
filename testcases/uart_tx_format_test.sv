class uart_tx_format_test extends uart_base_test;
    `uvm_component_utils(uart_tx_format_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        int count=0;
        for(int osm=0; osm<2; osm++)
          for(int width=5; width<=8; width++)
            for(int parity=0; parity<3; parity++)
              for(int stops=1; stops<=2; stops++) begin
                configure_uart(width,parity,stops,osm,4);
                write_reg('h18,'h00); write_reg('h18,'hff); write_reg('h18,'h55); write_reg('h18,'haa);
                count+=4; wait_tx(count);
              end
        require_counts(192,0);
    endtask
endclass
