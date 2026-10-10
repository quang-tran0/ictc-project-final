class uart_regmodel_test extends uart_base_test;
    `uvm_component_utils(uart_regmodel_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        uvm_status_e status;
        uvm_reg_data_t value;
        uart_reg_block model=uart_reg_block::type_id::create("model");
        uart_reg_adapter adapter=uart_reg_adapter::type_id::create("adapter");
        model.build(); model.default_map.set_sequencer(env.ahb.sequencer,adapter);
        model.default_map.set_auto_predict(1);
        for(int i=0; i<6; i++) begin
            model.regs[i].mirror(status,UVM_CHECK,UVM_FRONTDOOR);
            check_value(status==UVM_IS_OK,"RAL_RESET","Frontdoor reset mirror failed");
        end
        for(int i=0; i<5; i++) begin
            model.regs[i].write(status,(i==3) ? 'h1f : 'haa,UVM_FRONTDOOR);
            check_value(status==UVM_IS_OK,"RAL_WRITE","Frontdoor write failed");
            model.regs[i].mirror(status,UVM_CHECK,UVM_FRONTDOOR);
            check_value(status==UVM_IS_OK,"RAL_MIRROR","Frontdoor mirror failed");
        end
        reset_dut(); model.reset();
        for(int i=0; i<6; i++) model.regs[i].mirror(status,UVM_CHECK,UVM_FRONTDOOR);
    endtask
endclass
