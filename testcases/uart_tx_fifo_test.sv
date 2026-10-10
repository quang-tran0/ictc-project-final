class uart_tx_fifo_test extends uart_base_test;
    `uvm_component_utils(uart_tx_fifo_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart();
        for(int round_no=0; round_no<3; round_no++) begin
            write_reg('hc,3);
            for(int i=0; i<17; i++) begin
                write_reg('h18,i+round_no*32);
                if(i>0) check_reg('h14,i==16 ? 1 : 0,3,"TX_FIFO_FLAGS");
            end
            repeat(3) reject_full_tx('hee);
            check_reg('h18,0); check_reg('h14,1,3);
            write_reg('hc,'h23); wait_tx((round_no+1)*17);
            check_reg('h14,2,3);
        end
        check_value(env.scoreboard.tx_dropped==9,"TX_FULL_DROP_COUNT","Expected 9 full-FIFO writes ignored");
        require_counts(51,0);
    endtask
endclass
