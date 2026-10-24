// VPlan 7.10: Parity error interrupt masked
class uart_intr_parity_error_mask_test extends uart_base_test;
    `uvm_component_utils(uart_intr_parity_error_mask_test)

    function new(string name = "uart_intr_parity_error_mask_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_input = 1;
        inject_error();
        bus_write('h010, 0);
        check_irq(0);
        read_expect('h014, 'h10, 'h10, "Masked parity source remains set");
    endtask
endclass
