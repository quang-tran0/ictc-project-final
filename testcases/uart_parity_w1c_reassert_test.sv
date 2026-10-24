// VPlan 8.04: Parity error clear and reassert
class uart_parity_w1c_reassert_test extends uart_base_test;
    `uvm_component_utils(uart_parity_w1c_reassert_test)

    function new(string name = "uart_parity_w1c_reassert_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_input = 2;
        inject_error();
        bus_write('h014, 'h10);
        read_expect('h014, 0, 'h10);
        send_rx('{8'h59}, 1);
        read_expect('h014, 'h10, 'h10, "Fresh error reasserts status");
        bus_write('h014, 0);
        read_expect('h014, 'h10, 'h10, "Write0 leaves reasserted flag set");
    endtask
endclass
