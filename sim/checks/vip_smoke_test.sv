class vip_smoke_test extends uvm_test;
    `uvm_component_utils(vip_smoke_test)
    ahb_configuration acfg, passive_acfg;
    uart_configuration ucfg, passive_ucfg;
    ahb_agent ahb, passive_ahb;
    uart_agent uart, passive_uart;
    uvm_tlm_analysis_fifo #(ahb_transaction) ahb_obs, passive_ahb_obs;
    uvm_tlm_analysis_fifo #(uart_transaction) uart_obs, passive_uart_obs, uart_requests;
    int checks, ahb_transfers, uart_frames;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void verify(bit ok, string message);
        checks++;
        if (!ok) `uvm_error("VIP_CHECK", message)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        acfg = ahb_configuration::type_id::create("acfg");
        ucfg = uart_configuration::type_id::create("ucfg");
        if (!uvm_config_db #(virtual ahb_if)::get(this, "", "ahb_vif", acfg.vif) ||
            !uvm_config_db #(virtual uart_if)::get(this, "", "uart_vif", ucfg.vif))
            `uvm_fatal("VIP_VIF", "Smoke interfaces missing")
        passive_acfg = ahb_configuration::type_id::create("passive_acfg");
        passive_acfg.vif = acfg.vif;
        passive_acfg.is_active = UVM_PASSIVE;
        passive_ucfg = uart_configuration::type_id::create("passive_ucfg");
        passive_ucfg.vif = ucfg.vif;
        passive_ucfg.is_active = UVM_PASSIVE;
        ucfg.reset_n = 0;
        passive_ucfg.reset_n = 0;
        uvm_config_db #(ahb_configuration)::set(this, "ahb", "cfg", acfg);
        uvm_config_db #(ahb_configuration)::set(this, "passive_ahb", "cfg", passive_acfg);
        uvm_config_db #(uart_configuration)::set(this, "uart", "cfg", ucfg);
        uvm_config_db #(uart_configuration)::set(this, "passive_uart", "cfg", passive_ucfg);
        ahb = ahb_agent::type_id::create("ahb", this);
        passive_ahb = ahb_agent::type_id::create("passive_ahb", this);
        uart = uart_agent::type_id::create("uart", this);
        passive_uart = uart_agent::type_id::create("passive_uart", this);
        ahb_obs = new("ahb_obs", this);
        passive_ahb_obs = new("passive_ahb_obs", this);
        uart_obs = new("uart_obs", this);
        passive_uart_obs = new("passive_uart_obs", this);
        uart_requests = new("uart_requests", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        ahb.monitor_ap.connect(ahb_obs.analysis_export);
        passive_ahb.monitor_ap.connect(passive_ahb_obs.analysis_export);
        uart.monitor_ap.connect(uart_obs.analysis_export);
        passive_uart.monitor_ap.connect(passive_uart_obs.analysis_export);
        uart.driver_ap.connect(uart_requests.analysis_export);
    endfunction

    function void add_bus(ahb_smoke_sequence seq, bit wr, bit [9:0] addr,
                          bit [31:0] data, bit [31:0] expected_read = 0,
                          bit incr = 0);
        ahb_transaction item = ahb_transaction::type_id::create("bus_item");
        item.addr = addr;
        item.xact_type = wr ? ahb_transaction::WRITE : ahb_transaction::READ;
        item.data = data;
        item.rdata = expected_read; // Test expectation only; driver must replace this.
        item.burst_type = incr ? ahb_transaction::AHB_INCR : ahb_transaction::AHB_SINGLE;
        seq.items.push_back(item);
    endfunction

    task bus_checks();
        ahb_smoke_sequence seq = ahb_smoke_sequence::type_id::create("bus_seq");
        uart_reg_adapter adapter = uart_reg_adapter::type_id::create("adapter");
        ahb_transaction observed, passive, response;
        uvm_reg_bus_op op;
        add_bus(seq, 1, 'h0, 1);
        add_bus(seq, 1, 'h4, 'ha5, 0, 1);
        add_bus(seq, 0, 'h0, 'hdeadbeef, 1);
        add_bus(seq, 0, 'h4, 'hdeadbeef, 'ha5, 1);
        add_bus(seq, 1, 'h8, 'h5a);
        add_bus(seq, 0, 'h8, 'hdeadbeef, 'h5a);
        add_bus(seq, 0, 'h20, 0, 'hffffffff);
        add_bus(seq, 1, 'h3fc, 'h12345678);
        add_bus(seq, 0, 'h4, 0, 'ha5);
        seq.start(ahb.sequencer);
        verify(seq.responses.size() == seq.items.size(), "One response per request");
        verify(adapter.provides_responses, "RAL consumes separate completion responses");
        foreach (seq.items[i]) begin
            response = seq.responses[i];
            ahb_obs.get(observed);
            passive_ahb_obs.get(passive);
            verify(response.completed && observed.completed && passive.completed,
                  "Only completed transactions published");
            verify(response.addr == seq.items[i].addr && observed.addr == response.addr &&
                  passive.addr == response.addr, "Response/monitor address association");
            verify(response.xact_type == seq.items[i].xact_type &&
                  observed.xact_type == response.xact_type, "Direction association");
            verify(observed.xfer_size == ahb_transaction::SIZE_32BIT &&
                  observed.burst_type == seq.items[i].burst_type, "Observed size and burst");
            verify(response.get_transaction_id() == seq.items[i].get_transaction_id(),
                  "Response carries request transaction ID");
            verify(response.hresp === (seq.items[i].addr >= 'h20) &&
                  observed.hresp === response.hresp && passive.hresp === response.hresp,
                  "Expected HRESP, including reserved region");
            if (seq.items[i].xact_type == ahb_transaction::READ)
                verify(response.rdata === seq.items[i].rdata &&
                      observed.rdata === seq.items[i].rdata && passive.rdata === observed.rdata,
                      $sformatf("Completed HRDATA at %h: got %h expected %h",
                                response.addr, response.rdata, seq.items[i].rdata));
            else
                verify(response.data === seq.items[i].data && observed.data === response.data &&
                      passive.data === observed.data, "Completed write-data phase");
            adapter.bus2reg(response, op);
            verify(op.status == (response.hresp ? UVM_NOT_OK : UVM_IS_OK), "RAL status mapping");
            verify(op.data === (op.kind == UVM_READ ? response.rdata : response.data),
                  "RAL completed payload");
            ahb_transfers++;
        end
        repeat (3) @(posedge acfg.vif.HCLK);
        verify(ahb_obs.used() == 0 && passive_ahb_obs.used() == 0, "No duplicate AHB observations");
    endtask

    task bus_reset_check();
        ahb_smoke_sequence seq = ahb_smoke_sequence::type_id::create("reset_seq");
        add_bus(seq, 1, 'h8, 'h77);
        fork
            seq.start(ahb.sequencer);
            begin
                wait (acfg.vif.HSEL && acfg.vif.HTRANS[1]);
                wait (acfg.vif.HREADYOUT === 0);
                #2ns;
                acfg.vif.HRESETn = 0;
                #23ns;
                acfg.vif.HRESETn = 1;
            end
        join
        verify(seq.responses.size() == 1 && !seq.responses[0].completed,
              "Reset returns an aborted response without deadlock");
        repeat (3) @(posedge acfg.vif.HCLK);
        verify(ahb_obs.used() == 0 && passive_ahb_obs.used() == 0,
              "Reset-aborted AHB transfer is not published");
    endtask

    function void configure_uart(int width, uart_parity_e parity, int stops, realtime period);
        ucfg.data_width = width;
        ucfg.parity_mode = parity;
        ucfg.num_of_stop_bit = stops;
        ucfg.set_bit_period(period);
        passive_ucfg.data_width = width;
        passive_ucfg.parity_mode = parity;
        passive_ucfg.num_of_stop_bit = stops;
        passive_ucfg.set_bit_period(period);
    endfunction

    function uart_transaction serial_item(bit [7:0] data, bit parity_error = 0,
                                          bit stop_error = 0);
        uart_transaction item = uart_transaction::type_id::create("serial_item");
        item.data = data;
        item.direction = UART_TX;
        item.inject_parity_error = parity_error;
        item.inject_stop_error = stop_error;
        item.stop_error_index = ucfg.num_of_stop_bit - 1;
        return item;
    endfunction

    // Independent pin source, not a second call to uart_driver encoding logic.
    task external_frame(bit [7:0] data, int width, uart_parity_e parity,
                        int stops, realtime period, bit bad_parity = 0);
        int ones = 0;
        ucfg.vif.rx = 0;
        #(period);
        for (int i = 0; i < width; i++) begin
            ucfg.vif.rx = data[i];
            if (data[i]) ones++;
            #(period);
        end
        if (parity != UART_PARITY_NONE) begin
            ucfg.vif.rx = ((ones % 2) != (parity == UART_PARITY_ODD)) ^ bad_parity;
            #(period);
        end
        ucfg.vif.rx = 1;
        repeat (stops) #(period);
    endtask

    task uart_format_check(int width, uart_parity_e parity, int stops, realtime period);
        uart_smoke_sequence seq = uart_smoke_sequence::type_id::create("serial_seq");
        uart_transaction observed, passive, request;
        bit [7:0] tx_expected[3], rx_expected[3];
        int tx_count = 0, rx_count = 0;
        configure_uart(width, parity, stops, period);
        tx_expected = '{8'ha5 & (8'hff >> (8-width)), 8'h00, 8'hff >> (8-width)};
        rx_expected = '{8'h5a & (8'hff >> (8-width)), 8'hff >> (8-width), 8'h01};
        seq.items.push_back(serial_item('ha5));
        seq.items.push_back(serial_item('h00, parity != UART_PARITY_NONE));
        seq.items.push_back(serial_item('hff));
        fork
            seq.start(uart.sequencer);
            begin
                // Align starts on both independent wires; TX ending must not kill RX.
                @(negedge ucfg.vif.tx);
                #(period / 4.0);
                foreach (rx_expected[i])
                    external_frame(rx_expected[i], width, parity, stops, period,
                                   i == 2 && parity != UART_PARITY_NONE);
            end
        join
        repeat (6) begin
            uart_obs.get(observed);
            passive_uart_obs.get(passive);
            verify(observed.completed && !observed.baud_error && !observed.stop_error,
                  "Completed frame has legal timing/stops");
            verify(passive.data === observed.data && passive.direction == observed.direction &&
                  passive.parity_error == observed.parity_error, "Passive UART observation");
            if (observed.direction == UART_TX) begin
                verify(tx_count < 3, "No extra TX frame");
                if (tx_count < 3) begin
                    verify(observed.data === tx_expected[tx_count], "TX independent expected byte");
                    verify(observed.parity_error == (tx_count == 1 && parity != UART_PARITY_NONE),
                          "TX parity injection metadata");
                end
                tx_count++;
            end else begin
                verify(rx_count < 3, "No extra RX frame");
                if (rx_count < 3) begin
                    verify(observed.data === rx_expected[rx_count], "RX independent expected byte");
                    verify(observed.parity_error == (rx_count == 2 && parity != UART_PARITY_NONE),
                          "RX parity error metadata");
                end
                rx_count++;
            end
            uart_frames++;
        end
        verify(tx_count == 3 && rx_count == 3, "Both independent monitor workers survive");
        foreach (seq.items[i]) begin
            uart_requests.get(request);
            verify(request.data === tx_expected[i] && request.direction == UART_TX,
                  "Driver request publication is normalized");
            verify(!request.completed && seq.items[i].completed,
                  "Request snapshot remains independent of completed sequence item");
        end
        #(period);
        verify(uart_obs.used() == 0 && passive_uart_obs.used() == 0 && uart_requests.used() == 0,
              "No duplicate or missing UART publications");
    endtask

    task uart_reset_check();
        uart_smoke_sequence seq = uart_smoke_sequence::type_id::create("serial_reset");
        uart_transaction request;
        seq.items.push_back(serial_item('h55));
        fork
            seq.start(uart.sequencer);
            begin
                @(negedge ucfg.vif.tx);
                #(ucfg.bit_period() * 2.2);
                ucfg.reset_n = 0;
                passive_ucfg.reset_n = 0;
                #(ucfg.bit_period());
                ucfg.reset_n = 1;
                passive_ucfg.reset_n = 1;
            end
        join
        uart_requests.get(request);
        verify(!seq.items[0].completed && ucfg.vif.tx === 1, "UART reset aborts and idles");
        verify(uart_obs.used() == 0 && passive_uart_obs.used() == 0,
              "Aborted serial frame not published");
    endtask

    task uart_negative_checks();
        uart_smoke_sequence seq = uart_smoke_sequence::type_id::create("stop_error_seq");
        uart_transaction observed, passive, request;
        configure_uart(8, UART_PARITY_NONE, 2, 1000ns);
        seq.items.push_back(serial_item('h3c, 1, 1));
        seq.start(uart.sequencer);
        uart_obs.get(observed);
        passive_uart_obs.get(passive);
        uart_requests.get(request);
        verify(observed.data === 8'h3c && observed.stop_error && !observed.parity_error &&
               !observed.baud_error && passive.stop_error, "Second stop-bit injection observed");
        verify(!request.inject_parity_error, "No-parity request normalizes parity injection");
        uart_frames++;

        // A runt start is not a frame. Then an independently timed frame must decode.
        ucfg.vif.rx = 0;
        #200ns;
        ucfg.vif.rx = 1;
        #1800ns;
        verify(uart_obs.used() == 0 && passive_uart_obs.used() == 0, "Runt start rejected");
        // 5% baud mismatch exceeds 2% tolerance but still samples this frame cleanly.
        external_frame('h55, 8, UART_PARITY_NONE, 2, 1050ns);
        uart_obs.get(observed);
        passive_uart_obs.get(passive);
        verify(observed.direction == UART_RX && observed.data === 8'h55 &&
               observed.baud_error && passive.baud_error,
               "Baud violation remains visible to independent checker");
        verify(!observed.stop_error && !observed.parity_error,
               "Baud check does not manufacture parity/stop failures");
        uart_frames++;
    endtask

    function void configuration_checks();
        ahb_transaction item = ahb_transaction::type_id::create("random_item");
        uart_configuration cfg = uart_configuration::type_id::create("config_check");
        repeat (20) begin
            verify(item.randomize(), "AHB legal randomization");
            verify(item.addr <= 'h1c && item.addr[1:0] == 0 &&
                   item.xfer_size == ahb_transaction::SIZE_32BIT &&
                   item.burst_type inside {ahb_transaction::AHB_SINGLE, ahb_transaction::AHB_INCR},
                   "Random AHB traffic stays within supported scope");
        end
        verify(item.randomize() with {addr == 'h3fc;}, "Directed reserved address overrides soft default");
        cfg.data_width = 9;
        verify(!cfg.is_valid(), "Nine-bit UART rejected");
        cfg.data_width = 8;
        cfg.set_baud_rate(100.0e6 / (54 * 16));
        verify(cfg.bit_period() > 8639.999ns && cfg.bit_period() < 8640.001ns,
               "Fractional actual baud converts to exact period");
        cfg.configured_bit_period = 0;
        cfg.baud_rate = 0;
        verify(!cfg.is_valid(), "Zero baud rejected");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        configuration_checks();
        verify(ahb.driver != null && ahb.sequencer != null && uart.driver != null &&
              uart.sequencer != null, "ACTIVE components created");
        verify(passive_ahb.driver == null && passive_ahb.sequencer == null &&
              passive_uart.driver == null && passive_uart.sequencer == null,
              "PASSIVE agents create monitors only");
        wait (acfg.vif.HRESETn === 1);
        ucfg.reset_n = 1;
        passive_ucfg.reset_n = 1;
        bus_reset_check();
        bus_checks();
        uart_format_check(8, UART_PARITY_NONE, 1, 8640ns); // 54 * 16 * 10ns
        uart_format_check(5, UART_PARITY_NONE, 1, 1s / 2400.0);
        uart_format_check(6, UART_PARITY_EVEN, 2, 104130ns); // 801 * 13 * 10ns
        uart_format_check(7, UART_PARITY_ODD, 2, 1600ns);
        uart_format_check(8, UART_PARITY_EVEN, 1, 1300ns);
        uart_reset_check();
        uart_format_check(8, UART_PARITY_ODD, 1, 8640ns);
        uart_negative_checks();
        phase.drop_objection(this);
    endtask

    function void report_phase(uvm_phase phase);
        uvm_report_server server = uvm_report_server::get_server();
        if (server.get_severity_count(UVM_ERROR) == 0 &&
            server.get_severity_count(UVM_FATAL) == 0 && ahb_transfers == 9 && uart_frames == 38)
            `uvm_info("VIP_CHECK", $sformatf("VIP SMOKE PASSED: %0d checks, %0d AHB transfers, %0d UART frames",
                      checks, ahb_transfers, uart_frames), UVM_NONE)
        else
            `uvm_error("VIP_CHECK", "VIP SMOKE FAILED")
    endfunction
endclass
