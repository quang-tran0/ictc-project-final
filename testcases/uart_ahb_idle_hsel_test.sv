// VPlan 2.07: Inactive selection and IDLE
class uart_ahb_idle_hsel_test extends uart_base_test;
    `uvm_component_utils(uart_ahb_idle_hsel_test)

    function new(string name = "uart_ahb_idle_hsel_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        uart_ahb_sequence s;
        s = uart_ahb_sequence::type_id::create("inactive_cycles");
        s.add(1, 'h000, 1, 0, 0, 2'b10);
        s.add(1, 'h004, 'hff, 0, 1, 2'b00);
        s.start(env.ahb.sequencer);
        read_expect('h000, 0, 1, "HSEL0 cannot write MDR");
        read_expect('h004, 0, 'hff, "IDLE cannot write DLL");
    endtask
endclass
