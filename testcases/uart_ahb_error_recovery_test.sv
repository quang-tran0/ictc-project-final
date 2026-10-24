// VPlan 11.06: AHB error followed by valid transfer
// Check response/address association when a valid access follows ERROR.
class uart_ahb_error_recovery_test extends uart_base_test;
    `uvm_component_utils(uart_ahb_error_recovery_test)

    function new(string name = "uart_ahb_error_recovery_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        uart_ahb_sequence s;
        minimum_tx = 1;
        minimum_rx = 2;
        configure_uart();
        send_rx('{8'ha6, 8'hb7});
        s = uart_ahb_sequence::type_id::create("errors_then_fifo_access");
        s.add(0, 'h020);
        s.add(1, 'h000, 0);
        s.add(0, 'h000);
        s.add(1, 'h3fc, 'hdeadbeef);
        s.add(1, 'h018, 'h55);
        s.add(0, 'h01c);
        s.add(0, 'h3fc);
        s.add(1, 'h004, 'h36);
        s.add(0, 'h01c);
        s.add(0, 'h004);
        s.start(env.ahb.sequencer);
        foreach (s.responses[i]) expect_value(s.responses[i].hresp, s.transfers[i].addr >= 'h020, 1, "AHB error recovery response");
        expect_value(s.responses[2].rdata, 0, 1, "Valid read after error");
        expect_value(s.responses[9].rdata, 'h36, 'hff, "Final valid read");
        read_expect('h014, 8, 'h0c, "Two RBR pops completed once");
        wait_tx(1);
    endtask
endclass
