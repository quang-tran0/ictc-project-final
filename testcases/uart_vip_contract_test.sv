// Standalone VIP on isolated loopback: no scoreboard can report its errors.
class uart_vip_contract_test extends uvm_test;
    `uvm_component_utils(uart_vip_contract_test)
    uart_configuration cfg;
    uart_agent agent;
    virtual ahb_if reset_vif;
    uart_expected_error_catcher catcher;
    int checks;
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg=uart_configuration::type_id::create("cfg");
        if(!uvm_config_db#(virtual uart_if)::get(this,"","checker_vif",cfg.vif) ||
           !uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",reset_vif))
            `uvm_fatal("CHECKER_VIF","Missing isolated fixture")
        uvm_config_db#(uart_configuration)::set(this,"agent","cfg",cfg);
        agent=uart_agent::type_id::create("agent",this);
    endfunction
    function void check_value(bit condition,string detail);
        checks++;
        if(!condition) `uvm_error("VIP_CONTRACT",detail)
    endfunction
    task run_phase(uvm_phase phase);
        uart_frame_sequence s;
        time requested, bt, first_start, second_start;
        phase.raise_objection(this);
        reset_vif.HRESETn=0; #100ns;
        check_value(cfg.randomize() with {
            data_width==5; parity==UART_PARITY_ODD; num_of_stop_bits==2;
            osm_sel==1; divisor==65535;
        },"Configuration must randomize to a requested legal frame format");
        repeat(100) begin
            check_value(cfg.randomize(),"Legal frame configuration randomization failed");
            check_value(cfg.is_valid(),"Random configuration violates UART limits");
        end
        cfg.data_width=8; cfg.parity=uart_configuration::UART_PARITY_NONE;
        cfg.num_of_stop_bits=1; cfg.osm_sel=0; cfg.divisor=4;
        bt=640ns;
        reset_vif.HRESETn=1; #10ns;
        catcher=new; catcher.catch_format_errors=1;
        uvm_report_cb::add(agent.monitor,catcher);
        s=uart_frame_sequence::type_id::create("frame"); s.data='h55;
        requested=$time;
        fork
            s.start(agent.sequencer);
            begin
                @(negedge cfg.vif.tx);
                check_value($time>=requested+1ns,"Default start delay must leave idle time before start bit");
            end
        join
        check_value(agent.driver.sent_count==1,"Driver did not complete the valid frame");
        check_value(catcher.tx_parity==0 && catcher.rx_parity==0 &&
                    catcher.tx_stop==0 && catcher.rx_stop==0,"Valid frame reported a format error");
        cfg.parity=uart_configuration::UART_PARITY_EVEN;
        s.data=0; s.bad_parity=1; s.start(agent.sequencer);
        check_value(catcher.tx_parity==1 && catcher.rx_parity==1,
                    "Monitor alone must report bad parity in both directions");
        cfg.parity=uart_configuration::UART_PARITY_NONE;
        // Hand-generated 8N1 with a low stop bit; driver is idle.
        cfg.vif.tx=0; #(bt*10); cfg.vif.tx=1; #(bt);
        check_value(catcher.tx_stop==1 && catcher.rx_stop==1,
                    "Monitor alone must report low stop bits in both directions");
        cfg.start_delay=0; s.data=0; s.bad_parity=0;
        fork
            begin repeat(2) s.start(agent.sequencer); end
            begin
                @(negedge cfg.vif.tx); first_start=$time;
                @(negedge cfg.vif.tx); second_start=$time;
            end
        join
        check_value(second_start-first_start==6400ns,
                    "Zero start delay must preserve contiguous 8N1 frames");
        check_value(catcher.tx_parity==1 && catcher.rx_parity==1 &&
                    catcher.tx_stop==1 && catcher.rx_stop==1,
                    "Valid contiguous frames produced extra format errors");
        // Negative self-check: this variant must fail with unfinished frames.
        if($test$plusargs("VIP_TEST_TRAILING_FRAME")) begin
            cfg.vif.tx=0; #5ns;
        end
        phase.drop_objection(this);
    endtask
    function void report_phase(uvm_phase phase);
        uvm_report_server server=uvm_report_server::get_server();
        `uvm_info("CHECKS",$sformatf("Standalone VIP checks=%0d",checks),UVM_NONE)
        if(checks>0 && server.get_severity_count(UVM_ERROR)==0 && server.get_severity_count(UVM_FATAL)==0)
            `uvm_info("TEST_STATUS","TEST PASSED",UVM_NONE)
        else `uvm_error("TEST_STATUS","TEST FAILED")
    endfunction
endclass
