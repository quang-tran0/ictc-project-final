// VPlan 8.05: Parity disabled ignores EPS
class uart_parity_disabled_eps_test extends uart_base_test;
    `uvm_component_utils(uart_parity_disabled_eps_test)

    function new(string name = "uart_parity_disabled_eps_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_rx = 2;
        configure_uart();
        send_rx('{8'ha6});
        drain_rx(1);
        bus_write('h00c, 'h33);
        send_rx('{8'ha6});
        drain_rx(1);
        read_expect('h014, 0, 'h10, "PEN0 ignores EPS0 and EPS1");
    endtask
endclass
