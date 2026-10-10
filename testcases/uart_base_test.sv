class uart_base_test extends uvm_test;
    `uvm_component_utils(uart_base_test)
    ahb_configuration ahb_cfg;
    uart_configuration uart_cfg;
    uart_environment env;
    int unsigned checks;
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_cfg = ahb_configuration::type_id::create("ahb_cfg");
        uart_cfg = uart_configuration::type_id::create("uart_cfg");
        if (!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_cfg.vif))
            `uvm_fatal("AHB_VIF", "Missing interface")
        if (!uvm_config_db#(virtual uart_if)::get(this,"","uart_vif",uart_cfg.vif))
            `uvm_fatal("UART_VIF", "Missing interface")
        uvm_config_db#(ahb_configuration)::set(this,"env.ahb","cfg",ahb_cfg);
        uvm_config_db#(uart_configuration)::set(this,"env.uart","cfg",uart_cfg);
        env = uart_environment::type_id::create("env",this);
    endfunction
    task cycles(int unsigned n=4); repeat(n) @(negedge ahb_cfg.vif.HCLK); endtask
    task reset_dut();
        @(negedge ahb_cfg.vif.HCLK); ahb_cfg.vif.HRESETn = 0;
        env.scoreboard.reset_model();
        cycles(10); ahb_cfg.vif.HRESETn = 1; cycles(4);
    endtask
    function void check_value(bit condition, string id, string detail);
        checks++;
        if (!condition) `uvm_error(id, detail)
    endfunction
    task access(bit write_enable, bit [9:0] addr, bit [31:0] data,
                output logic [31:0] rdata, input bit incr=0,
                input bit [1:0] trans=2, input bit selected=1);
        ahb_access_sequence s = ahb_access_sequence::type_id::create("access");
        s.item = ahb_transaction::type_id::create("item");
        s.item.kind = write_enable ? ahb_transaction::WRITE : ahb_transaction::READ;
        s.item.addr = addr; s.item.data = data;
        s.item.burst = incr ? ahb_transaction::AHB_INCR : ahb_transaction::AHB_SINGLE;
        s.item.htrans = ahb_transaction::htrans_type_e'(trans); s.item.selected = selected;
        s.start(env.ahb.sequencer); rdata = s.item.rdata;
    endtask
    task write_reg(bit [9:0] addr, bit [31:0] data);
        logic [31:0] unused; access(1,addr,data,unused);
    endtask
    task read_reg(bit [9:0] addr, output logic [31:0] data);
        access(0,addr,0,data);
    endtask
    task check_reg(bit [9:0] addr, bit [31:0] expected, bit [31:0] mask='1, string id="DIRECTED_READ");
        logic [31:0] actual;
        read_reg(addr,actual);
        check_value((actual & mask) === (expected & mask), id,
              $sformatf("addr=%03h mask=%08h expected=%08h actual=%08h",addr,mask,expected,actual));
    endtask
    task configure_uart(int width=8, int parity=0, int stops=1, bit osm=0, int divisor=4);
        check_value(env.scoreboard.tx_expected.size()==0 && env.scoreboard.rx_expected.size()==0,
              "CONFIG_PENDING", "Reconfiguration with undrained traffic");
        write_reg('h0c,3); write_reg(0,osm);
        write_reg(4,divisor & 'hff); write_reg(8,divisor >> 8);
        uart_cfg.data_width=width; uart_cfg.parity=uart_configuration::uart_parity_e'(parity);
        uart_cfg.num_of_stop_bits=stops; uart_cfg.osm_sel=osm; uart_cfg.divisor=divisor;
        write_reg('h0c,'h20 | (width-5) | ((stops-1)<<2) | ((parity!=0)<<3) | ((parity==1)<<4));
        #(uart_cfg.bit_period()*2);
    endtask
    task check_irq(bit expected, string detail);
        cycles(4);
        env.coverage.irq_cg.sample(env.scoreboard.regs[4][4:0],ahb_cfg.vif.interrupt);
        check_value(ahb_cfg.vif.interrupt===expected,"IRQ_LEVEL",
                    $sformatf("%s expected=%b actual=%b",detail,expected,ahb_cfg.vif.interrupt));
    endtask
    task send_rx(bit [7:0] data, bit bad_parity=0);
        uart_frame_sequence s = uart_frame_sequence::type_id::create("rx_frame");
        env.scoreboard.expect_rx(data,bad_parity);
        s.data=data; s.bad_parity=bad_parity; s.start(env.uart.sequencer);
    endtask
    task read_rx(int unsigned n);
        logic [31:0] status, data;
        repeat(n) begin
            status='h8;
            for (int i=0; i<200 && status[3]; i++) begin
                read_reg('h14,status);
                if (status[3]) #(uart_cfg.bit_period()/4);
            end
            if (status[3]) `uvm_fatal("RX_TIMEOUT", "No receive data before deadline")
            read_reg('h1c,data);
        end
        cycles();
    endtask
    task wait_tx(int unsigned target);
        bit done;
        done=0;
        fork : tx_deadline
            begin wait(env.scoreboard.tx_count>=target); done=1; end
            begin #(uart_cfg.frame_period()*(target+3)); end
        join_any
        disable tx_deadline;
        if (!done) `uvm_fatal("TX_TIMEOUT", $sformatf("expected=%0d got=%0d",target,env.scoreboard.tx_count))
        #(uart_cfg.bit_period()*2);
    endtask
    function void require_counts(int tx, int rx);
        check_value(env.scoreboard.tx_count==tx,"TX_COUNT",$sformatf("expected=%0d got=%0d",tx,env.scoreboard.tx_count));
        check_value(env.scoreboard.rx_count==rx,"RX_COUNT",$sformatf("expected=%0d got=%0d",rx,env.scoreboard.rx_count));
    endfunction
    virtual task scenario();
        `uvm_fatal("BASE_TEST", "Select a concrete testcase")
    endtask
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        reset_dut(); scenario(); cycles(10);
        phase.drop_objection(this);
    endtask
    function void report_phase(uvm_phase phase);
        uvm_report_server server = uvm_report_server::get_server();
        `uvm_info("CHECKS", $sformatf("Directed checks=%0d",checks), UVM_NONE)
        if (server.get_severity_count(UVM_ERROR)==0 && server.get_severity_count(UVM_FATAL)==0 &&
            checks>0 && env.scoreboard.compared_count>0)
            `uvm_info("TEST_STATUS", "TEST PASSED", UVM_NONE)
        else `uvm_error("TEST_STATUS", "TEST FAILED")
    endfunction
endclass
