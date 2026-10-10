class uart_irq_mask_test extends uart_base_test;
    `uvm_component_utils(uart_irq_mask_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        check_reg(0,0); check_reg('h14,'ha);
        for(int mask=0; mask<32; mask++) begin
            write_reg('h10,mask); cycles();
            env.coverage.irq_cg.sample(mask,ahb_cfg.vif.interrupt);
            check_value(ahb_cfg.vif.interrupt===((mask & 'ha)!=0),"IRQ_MASK",$sformatf("IER=%02h irq=%b",mask,ahb_cfg.vif.interrupt));
        end
        write_reg('h10,0);
    endtask
endclass
