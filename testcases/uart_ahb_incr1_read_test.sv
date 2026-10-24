// VPlan 2.03: One-beat undefined INCR read
class uart_ahb_incr1_read_test extends uart_base_test;
    `uvm_component_utils(uart_ahb_incr1_read_test)

    function new(string name = "uart_ahb_incr1_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        logic [31:0] d;
        bus_write('h004, 'h8b);
        bus_read('h004, d, 1);
        expect_value(d, 'h8b, 'hff, "One-beat INCR read");
    endtask
endclass
