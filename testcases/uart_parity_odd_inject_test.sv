// VPlan 8.02: Odd parity mismatch detection
// Check FSR.bit4; bad-frame FIFO retention is not specified.
class uart_parity_odd_inject_test extends uart_base_test;
    `uvm_component_utils(uart_parity_odd_inject_test)

    function new(string name = "uart_parity_odd_inject_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_input = 1;
        inject_error(UART_PARITY_ODD);
    endtask
endclass
