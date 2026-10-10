class uart_register_reset_test extends uart_base_test;
    `uvm_component_utils(uart_register_reset_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        repeat (2) begin
            check_reg(0,0); check_reg(4,0); check_reg(8,0);
            check_reg('hc,3); check_reg('h10,0); check_reg('h14,'ha); check_reg('h18,0);
            check_value(uart_cfg.vif.rx===1,"RESET_IDLE","TX not idle after reset");
            check_value(ahb_cfg.vif.interrupt===0,"RESET_IRQ","IRQ asserted after reset");
            write_reg(0,1); write_reg(4,8'hff); write_reg(8,8'hab); write_reg('h10,'h1f);
            reset_dut();
        end
    endtask
endclass
