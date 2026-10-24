// VPlan 8.03: Parity-error status sticky until W1C
class uart_parity_sticky_status_test extends uart_base_test;
    `uvm_component_utils(uart_parity_sticky_status_test)

    function new(string name = "uart_parity_sticky_status_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_input = 2;
        inject_error();
        send_rx('{8'h37});
        read_expect('h014, 'h10, 'h10, "Valid later frame does not clear sticky parity flag");
    endtask
endclass
