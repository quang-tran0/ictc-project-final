// VPlan 1.08: FSR parity status W1C
class uart_reg_fsr_w1c_test extends uart_base_test;
    `uvm_component_utils(uart_reg_fsr_w1c_test)

    function new(string name = "uart_reg_fsr_w1c_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        logic [31:0] saved;
        minimum_input = 1;
        inject_error();
        bus_read('h014, saved);
        bus_write('h014, 0);
        read_expect('h014, saved, 'h1f, "W1C write0 preserves flag/RO");
        bus_write('h014, 'h10);
        read_expect('h014, saved & 'h0f, 'h1f, "W1C write1 clears only parity");
    endtask
endclass
