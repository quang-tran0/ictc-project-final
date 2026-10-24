// VPlan 2.04: One-beat undefined INCR write
class uart_ahb_incr1_write_test extends uart_base_test;
    `uvm_component_utils(uart_ahb_incr1_write_test)

    function new(string name = "uart_ahb_incr1_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        bus_write('h000, 1, 1);
        read_expect('h000, 1, 1, "One-beat INCR write");
    endtask
endclass
