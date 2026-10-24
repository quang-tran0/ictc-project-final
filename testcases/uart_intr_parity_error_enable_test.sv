// VPlan 7.09: Parity error interrupt enabled
class uart_intr_parity_error_enable_test extends uart_base_test;
    `uvm_component_utils(uart_intr_parity_error_enable_test)

    function new(string name = "uart_intr_parity_error_enable_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_input = 1;
        inject_error();
        bus_write('h010, 'h10);
        check_irq(1);
        bus_write('h014, 'h10);
        read_expect('h014, 0, 'h10);
        check_irq(0);
    endtask
endclass
