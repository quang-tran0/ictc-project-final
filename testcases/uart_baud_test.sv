class uart_baud_test extends uart_base_test;
    `uvm_component_utils(uart_baud_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        int div16[13]='{1,2,54,81,163,325,651,1302,2604,255,256,257,65535};
        int div13[13]='{1,2,67,100,200,401,801,1602,3205,255,256,257,65535};
        int count=0;
        for(int osm=0; osm<2; osm++) begin
            for(int i=0; i<13; i++) begin
                time edge1, edge2, expected;
                configure_uart(8,0,1,osm,osm ? div13[i] : div16[i]);
                expected=uart_cfg.bit_period();
                fork
                    write_reg('h18,'h55);
                    begin
                        @(negedge uart_cfg.vif.rx); // Start
                        @(posedge uart_cfg.vif.rx); edge1=$time; // Data bit 0
                        @(negedge uart_cfg.vif.rx); edge2=$time; // Data bit 1
                        check_value(edge2-edge1==expected,"BAUD_PERIOD",
                            $sformatf("osm=%0d divisor=%0d expected=%0t actual=%0t",osm,uart_cfg.divisor,expected,edge2-edge1));
                    end
                join
                count++; wait_tx(count); send_rx('ha6); read_rx(1);
            end
        end
        require_counts(26,26);
    endtask
endclass
