// VPlan 1.01: Register reset defaults
class uart_reg_reset_test extends uart_base_test;
    `uvm_component_utils(uart_reg_reset_test)

    function new(string name = "uart_reg_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        check_reset_defaults();
    endtask
endclass
