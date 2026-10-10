// Exercise the checker itself: a late frame must be rejected before it completes.
class uart_monitor_tail_test extends uart_base_test;
    `uvm_component_utils(uart_monitor_tail_test)
    uart_expected_error_catcher catcher;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual uart_if)::get(this,"","checker_vif",uart_cfg.vif))
            `uvm_fatal("CHECKER_VIF","Missing isolated monitor fixture")
    endfunction
    task scenario();
        check_reg(0,0);
        catcher=new; catcher.catch_incomplete_errors=1;
        uvm_report_cb::add(env.uart.monitor,catcher);
        uart_cfg.vif.tx=0; // Isolated loopback, never drives/forces the DUT TX pin.
        cycles(5); // End before even the first data bit can be decoded.
    endtask
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        check_value(catcher.tx_caught==1 && catcher.rx_caught==1,"TAIL_CHECKER_COUNT",
                    $sformatf("Expected one unfinished-frame error per direction; TX=%0d RX=%0d",catcher.tx_caught,catcher.rx_caught));
    endfunction
endclass
