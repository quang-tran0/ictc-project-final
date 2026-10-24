// VPlan 2.08: Back-to-back single transfers
// Known failure: DLL reads 0x01 after pipelined MDR=1 and DLL=0xA5 writes.
class uart_ahb_back_to_back_test extends uart_base_test;
    `uvm_component_utils(uart_ahb_back_to_back_test)

    function new(string name = "uart_ahb_back_to_back_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        uart_ahb_sequence s;
        s = uart_ahb_sequence::type_id::create("pipelined_single");
        s.add(1, 'h000, 1);
        s.add(1, 'h004, 'ha5);
        s.add(0, 'h000);
        s.add(0, 'h004);
        s.start(env.ahb.sequencer);
        expect_value(s.responses[2].rdata, 1, 1, "Pipelined MDR read");
        expect_value(env.ahb.monitor.read_wait_cycles > 0, 1, 1, "Observed real READ wait state");
        expect_value(env.ahb.monitor.write_wait_cycles > 0, 1, 1, "Observed real WRITE wait state");
        expect_value(s.responses[3].rdata, 'ha5, 'hff, "Pipelined DLL read");
    endtask
endclass
