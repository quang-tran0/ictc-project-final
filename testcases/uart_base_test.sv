class uart_base_test extends uvm_test;
    `uvm_component_utils(uart_base_test)
    uart_environment env;
    ahb_configuration ahb_cfg;
    uart_configuration uart_cfg;
    virtual ahb_if ahb_vif;
    virtual uart_if uart_vif;
    virtual uart_irq_if irq_vif;
    int unsigned scenario_checks, minimum_tx, minimum_rx, minimum_input;
    bit scenario_finished = 0;

    function new(string name = "uart_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "ahb_vif", ahb_vif) || ahb_vif == null)
            `uvm_fatal("BASE_VIF", "Missing AHB interface")
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", uart_vif) || uart_vif == null)
            `uvm_fatal("BASE_VIF", "Missing UART interface")
        if (!uvm_config_db#(virtual uart_irq_if)::get(this, "", "uart_irq_vif", irq_vif) || irq_vif == null)
            `uvm_fatal("BASE_VIF", "Missing IRQ interface")
        ahb_cfg = ahb_configuration::type_id::create("ahb_cfg");
        ahb_cfg.vif = ahb_vif;
        uart_cfg = uart_configuration::type_id::create("uart_cfg");
        uart_cfg.vif = uart_vif;
        uvm_config_db#(ahb_configuration)::set(this, "env.ahb", "cfg", ahb_cfg);
        uvm_config_db#(uart_configuration)::set(this, "env.uart", "cfg", uart_cfg);
        uvm_config_db#(uart_configuration)::set(this, "env.scoreboard", "uart_cfg", uart_cfg);
        uvm_config_db#(virtual uart_irq_if)::set(this, "env.*", "uart_irq_vif", irq_vif);
        env = uart_environment::type_id::create("env", this);
        uvm_top.set_timeout(1s, 0);
    endfunction

    task clocks(int n = 2);
        repeat (n) @(negedge ahb_vif.HCLK);
    endtask

    task reset_dut();
        uart_cfg.monitor_enable = 0;
        @(negedge ahb_vif.HCLK);
        ahb_vif.HRESETn = 0;
        repeat (5) @(negedge ahb_vif.HCLK);
        ahb_vif.HRESETn = 1;
        env.regmodel.reset();
        clocks(2);
    endtask

    task configure_uart(int width = 8, uart_parity_e parity = UART_PARITY_NONE,
        int stops = 1, int osm = 16, int divisor = 54, bit enable = 1);
        uart_setup_sequence s;
        s = uart_setup_sequence::type_id::create("setup");
        s.env = env;
        s.cfg = uart_cfg;
        s.width = width;
        s.parity = parity;
        s.stops = stops;
        s.osm = osm;
        s.divisor = divisor;
        s.baud_enable = enable;
        s.start(null);
    endtask

    task bus_read(bit [9:0] addr, output logic [31:0] data, input bit incr = 0, input bit error_expected = 0);
        uart_ahb_sequence s;
        s = uart_ahb_sequence::type_id::create("read");
        s.add(0, addr, 0, incr);
        s.start(env.ahb.sequencer);
        data = s.responses[0].rdata;
        if (s.responses[0].hresp !== error_expected)
            `uvm_error("BUS_RESP", "Unexpected read HRESP")
    endtask

    task bus_write(bit [9:0] addr, bit [31:0] data, bit incr = 0, bit error_expected = 0);
        uart_ahb_sequence s;
        s = uart_ahb_sequence::type_id::create("write");
        s.add(1, addr, data, incr);
        s.start(env.ahb.sequencer);
        if (s.responses[0].hresp !== error_expected)
            `uvm_error("BUS_RESP", "Unexpected write HRESP")
    endtask

    function void expect_value(logic [31:0] actual, logic [31:0] expected, bit [31:0] mask, string label);
        scenario_checks++;
        if ((actual & mask) !== (expected & mask))
            `uvm_error("TEST_CHECK", $sformatf("%s actual=%08h expected=%08h mask=%08h", label, actual, expected, mask))
    endfunction

    task read_expect(bit [9:0] addr, bit [31:0] expected, bit [31:0] mask, string label = "register");
        logic [31:0] d;
        bus_read(addr, d);
        expect_value(d, expected, mask, label);
    endtask

    task wait_status(bit [4:0] mask, bit [4:0] expected, realtime budget = 0);
        realtime deadline;
        logic [31:0] d;
        deadline = $realtime + (budget > 0 ? budget : uart_cfg.frame_period() * 20 + 10us);
        do begin
            bus_read('h014, d);
            if ((d[4:0]&mask) === (expected&mask)) begin
                scenario_checks++;
                return;
            end
            // Poll once per bit, rather than generating millions of AHB reads.
            #(uart_cfg.bit_period());
        end
        while ($realtime < deadline);
        `uvm_error("STATUS_TIMEOUT", $sformatf("FSR=%02h mask=%02h expected=%02h", d, mask, expected))
    endtask

    task send_rx(byte unsigned bytes_to_send[$], bit bad_parity = 0, int gap_bits = 0);
        uart_rx_sequence s;
        s = uart_rx_sequence::type_id::create("rx_traffic");
        s.cfg = uart_cfg;
        s.bytes_to_send = bytes_to_send;
        s.bad_parity = bad_parity;
        s.gap_bits = gap_bits;
        s.start(env.uart.sequencer);
        clocks(2);
    endtask

    task transmit(byte unsigned bytes_to_send[$]);
        uart_tx_sequence s;
        s = uart_tx_sequence::type_id::create("tx_traffic");
        s.bus_sequencer = env.ahb.sequencer;
        s.bytes_to_send = bytes_to_send;
        s.start(null);
    endtask

    task drain_rx(int n);
        logic [31:0] d;
        repeat (n) begin
            wait_status('h08, 0);
            bus_read('h01c, d);
        end
        read_expect('h014, 'h08, 'h0c, "RX drained");
    endtask

    task random_serial_frames(bit receive, int count = 2);
        uart_random_sequence s;
        s = uart_random_sequence::type_id::create("format_random_traffic");
        s.cfg = uart_cfg;
        s.width = uart_cfg.data_width;
        s.receive = receive;
        s.serial_sequencer = env.uart.sequencer;
        s.bus_sequencer = env.ahb.sequencer;
        if (!s.randomize() with { frame_count == local::count; })
            `uvm_fatal("RAND_UART", "Cannot solve UART payload/gap constraints")
        s.start(null);

        if (receive) begin
            minimum_rx += count;
            clocks(2);
            drain_rx(count);
            read_expect('h014, 0, 'h10, "Random valid frames have no parity error");
        end else begin
            minimum_tx += count;
            wait_tx(minimum_tx);
        end
    endtask

    task random_register_writes(bit [9:0] address, bit [31:0] write_mask);
        uart_ahb_sequence s;
        bit [31:0] values[$];
        repeat (8) begin
            s = uart_ahb_sequence::type_id::create("random_register_write");
            s.add_random_write(address, write_mask);
            s.start(env.ahb.sequencer);
            values.push_back(s.transfers[0].data);
            read_expect(address, s.transfers[0].data, write_mask, "Random register readback");
        end
        `uvm_info("RAND_REGISTER", $sformatf("addr=%03h mask=%08h values=%p",
                  address, write_mask, values), UVM_LOW)
    endtask

    task wait_tx(int count);
        realtime deadline;
        deadline = $realtime + (count + 2) * uart_cfg.frame_period() + 10us;
        while (env.scoreboard.tx_compares < count && $realtime < deadline) #(uart_cfg.bit_period());
        if (env.scoreboard.tx_compares < count)
            `uvm_error("TX_TIMEOUT", "Expected TX frames did not arrive")
        // Catch extra output and let the last full stop interval complete.
        #(uart_cfg.frame_period());
        clocks(2);
    endtask

    task check_irq(bit expected);
        clocks(10);
        scenario_checks++;
        if (irq_vif.interrupt !== expected)
            `uvm_error("IRQ_CHECK", $sformatf("IRQ=%b expected=%b", irq_vif.interrupt, expected))
    endtask

    task check_reset_defaults();
        read_expect('h000, 0, 1, "MDR reset");
        read_expect('h004, 0, 'hff, "DLL reset");
        read_expect('h008, 0, 'hff, "DLH reset");
        read_expect('h00c, 3, 'h3f, "LCR reset");
        read_expect('h010, 0, 'h1f, "IER reset");
        read_expect('h014, 'h0a, 'h1f, "FSR reset");
    endtask

    task fill_tx();
        logic [31:0] d;
        configure_uart(8, UART_PARITY_NONE, 1, 16, 64);
        for (int i = 0; i < 18; i++) begin
            bus_read('h014, d);
            if (d[0] === 1) begin
                scenario_checks++;
                return;
            end
            bus_write('h018, 'h20 + i);
        end
        `uvm_error("FIFO_FULL", "TX did not become full within18 enqueues")
    endtask

    task inject_error(uart_parity_e parity = UART_PARITY_EVEN, byte unsigned data = 'hA6);
        env.scoreboard.check_rx_data = 0;
        configure_uart(8, parity);
        send_rx('{data}, 1);
        read_expect('h014, 'h10, 'h10, "Parity error set");
    endtask

    virtual task run_scenario();
        minimum_tx = 1;
        minimum_rx = 1;
        configure_uart();
        transmit('{8'h55});
        wait_tx(1);
        send_rx('{8'ha6});
        drain_rx(1);
    endtask

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        wait (ahb_vif.HRESETn === 1);
        clocks(2);
        reset_dut();
        fork : bounded_scenario
            begin
                run_scenario();
                scenario_finished = 1;
            end
            begin
                #500ms;
                `uvm_error("TEST_TIMEOUT", "Scenario exceeded500ms")
            end
        join_any
        disable bounded_scenario;
        clocks(10);
        phase.drop_objection(this);
    endtask

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (!scenario_finished)
            `uvm_error("TEST_INCOMPLETE", "Scenario did not finish")
        if (env.scoreboard.tx_compares < minimum_tx || env.scoreboard.rx_compares < minimum_rx ||
            env.scoreboard.input_compares < minimum_input || env.scoreboard.input_compares < minimum_rx)
            `uvm_error("TEST_ZERO_COMPARE", "Required data comparisons did not occur")
        if (scenario_checks == 0 && minimum_tx == 0 && minimum_rx == 0)
            `uvm_error("TEST_NO_CHECK", "Test has no scenario-specific check")
    endfunction

    function void report_phase(uvm_phase phase);
        uvm_report_server server;
        super.report_phase(phase);
        server = uvm_report_server::get_server();
        if (server.get_severity_count(UVM_ERROR) == 0 && server.get_severity_count(UVM_FATAL) == 0)
            `uvm_info("TEST_RESULT", "TEST PASSED", UVM_NONE)
        else
            `uvm_info("TEST_RESULT", "TEST FAILED", UVM_NONE)
    endfunction
endclass
