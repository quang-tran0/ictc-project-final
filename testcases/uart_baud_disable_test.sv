class uart_baud_disable_test extends uart_base_test;
    `uvm_component_utils(uart_baud_disable_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart(); write_reg('hc,3);
        write_reg('h18,'h55); write_reg('h18,'ha6);
        #(uart_cfg.frame_period()*3);
        check_value(env.scoreboard.tx_count==0 && uart_cfg.vif.rx===1,"BGE_DISABLE","TX sent with BGE=0");
        check_reg('h14,0,2);
        write_reg('hc,'h23); wait_tx(2); require_counts(2,0);
    endtask
endclass
