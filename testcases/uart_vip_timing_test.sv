// Infrastructure self-check, separate from the 150 DUT/VPlan tests.
// Reference symbols use a population count; the sampler checks three points
// per symbol without calling the VIP decoder or parity helper.
class uart_vip_timing_test extends uvm_test;
    `uvm_component_utils(uart_vip_timing_test)
    uart_agent uart;
    ahb_agent ahb;
    uart_configuration cfg;
    ahb_configuration acfg;
    virtual uart_if uvif;
    virtual ahb_if avif;
    uvm_tlm_analysis_fifo#(uart_transaction) serial_frames;
    uvm_tlm_analysis_fifo#(ahb_transaction) bus_transfers;
    int unsigned sampled_frames, decoded_frames, checked_transfers;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", uvif) ||
            !uvm_config_db#(virtual ahb_if)::get(this, "", "ahb_vif", avif))
            `uvm_fatal("VIP_CHECK_TOP", "Run with top uart_vip_check_top")
        cfg = uart_configuration::type_id::create("cfg");
        cfg.vif = uvif;
        cfg.monitor_enable = 1;
        acfg = ahb_configuration::type_id::create("acfg");
        acfg.vif = avif;
        uvm_config_db#(uart_configuration)::set(this, "uart", "cfg", cfg);
        uvm_config_db#(ahb_configuration)::set(this, "ahb", "cfg", acfg);
        uart = uart_agent::type_id::create("uart", this);
        ahb = ahb_agent::type_id::create("ahb", this);
        serial_frames = new("serial_frames", this);
        bus_transfers = new("bus_transfers", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        uart.monitor_ap.connect(serial_frames.analysis_export);
        ahb.monitor_ap.connect(bus_transfers.analysis_export);
    endfunction

    function void reference_symbols(byte unsigned data, output bit symbols[$],
        input bit bad_parity = 0, bit bad_stop = 0, int bad_stop_index = 0);
        int ones = 0;
        symbols.delete();
        symbols.push_back(0);
        for (int i = 0; i < cfg.data_width; i++) begin
            symbols.push_back(data[i]);
            if (data[i]) ones++;
        end
        if (cfg.parity_mode != UART_PARITY_NONE)
            symbols.push_back(((ones % 2) == (cfg.parity_mode == UART_PARITY_EVEN ? 1 : 0)) ^ bad_parity);
        for (int i = 0; i < cfg.num_of_stop_bit; i++) symbols.push_back(!(bad_stop && i == bad_stop_index));
    endfunction

    task reference_send(byte unsigned data, realtime period, bit bad_parity = 0,
        bit bad_stop = 0, bit glitch = 0);
        bit symbols[$];
        reference_symbols(data, symbols, bad_parity, bad_stop);
        foreach (symbols[i]) begin
            uvif.rx = symbols[i];
            if (glitch && i == 1) begin
                #(period / 5.0);
                uvif.rx = ~symbols[i];
                #(period / 10.0);
                uvif.rx = symbols[i];
                #(period * 0.7);
            end else #(period);
        end
        uvif.rx = 1;
    endtask

    task sample_driver(byte unsigned data, realtime period, bit bad_parity = 0,
        bit bad_stop = 0, int bad_stop_index = 0, realtime expected_start = -1);
        bit symbols[$];
        realtime started_at;
        reference_symbols(data, symbols, bad_parity, bad_stop, bad_stop_index);
        @(negedge uvif.tx);
        started_at = $realtime;
        if (expected_start >= 0 && (started_at < expected_start - 1ps || started_at > expected_start + 1ps))
            `uvm_error("VIP_DRIVER_START",
                $sformatf("Start at %0.3f ns; expected %0.3f ns",
                    started_at, expected_start))
        fork
            begin
                foreach (symbols[i]) begin
                    #(period / 4.0);
                    for (int point = 0; point < 3; point++) begin
                        if (uvif.tx !== symbols[i])
                            `uvm_error("VIP_DRIVER_SAMPLE",
                                $sformatf("data=%02h symbol=%0d expected=%b got=%b time=%0t",
                                    
                            data, i, symbols[i], uvif.tx, $time))
                        if (point < 2) #(period / 4.0);
                    end
                    if (i < symbols.size() - 1) #(period / 4.0);
                end
            end
            forever begin
                realtime elapsed, nearest_boundary;
                @(uvif.tx);
                elapsed = $realtime - started_at;
                nearest_boundary = real'(longint'(elapsed / period)) * period;
                if (elapsed < nearest_boundary - 1ps || elapsed > nearest_boundary + 1ps)
                    `uvm_error("VIP_DRIVER_EDGE", $sformatf("Driver edge at %0.3f ns, expected boundary %0.3f ns",
                    $realtime, started_at + nearest_boundary))
            end
        join_any
        disable fork;
        // This task is called for zero-gap frames too: finish before the next
        // start edge, rather than racing that edge in the next invocation.
        sampled_frames++;
    endtask

    task check_decoded(byte unsigned bytes[$], bit bad_parity = 0);
        uart_transaction frame;
        int next_index[2] = '{0, 0};
        repeat (2 * bytes.size()) begin
            serial_frames.get(frame);
            `uvm_info("VIP_DECODE", $sformatf("direction=%s data=%02h start=%0.3f ns period=%0.3f ns",
                frame.direction.name(), frame.data, frame.started_at, frame.period), UVM_HIGH)
            if (next_index[frame.direction] >= bytes.size())
                `uvm_fatal("VIP_FRAME_COUNT", "Unexpected extra frame on one UART direction")
            if (frame.data !== (bytes[next_index[frame.direction]] & (8'hff >> (8 - cfg.data_width))) ||
                frame.inject_parity_error != (bad_parity && cfg.parity_mode != UART_PARITY_NONE) ||
                frame.inject_stop_error || frame.data_width != cfg.data_width ||
                frame.stop_bits != cfg.num_of_stop_bit || frame.parity_mode != int'(cfg.parity_mode))
                `uvm_error("VIP_MONITOR_DECODE",
                    $sformatf("direction=%s index=%0d data=%02h parity_error=%b stop_error=%b",
                        
                frame.direction.name(), next_index[frame.direction], frame.data,
                frame.inject_parity_error, frame.inject_stop_error))
            next_index[frame.direction]++;
            decoded_frames++;
        end
    endtask

    task uart_matrix();
        byte unsigned patterns[$] = '{8'h00, 8'hff, 8'h55, 8'haa, 8'ha6, 8'h01, 8'h80, 8'h17};
        realtime period;
        realtime group_start;
        uart_rx_sequence traffic;
        for (int width = 5; width <= 8; width++)
            for (int parity = 0; parity < 3; parity++)
                for (int stops = 1; stops <= 2; stops++)
                    for (int osm = 13; osm <= 16; osm += 3) begin
            cfg.data_width = width;
            cfg.parity_mode = uart_parity_e'(parity);
            cfg.num_of_stop_bit = stops;
            cfg.oversampling = osm;
            period = osm == 13 ? 130.125ns : 160.375ns;
            cfg.programmed_period = period;
            `uvm_info("VIP_MATRIX", $sformatf("width=%0d parity=%0d stops=%0d osm=%0d sampled=%0d decoded=%0d",
                width, parity, stops, osm, sampled_frames, decoded_frames), UVM_HIGH)
            traffic = uart_rx_sequence::type_id::create("matrix_traffic");
            traffic.cfg = cfg;
            traffic.bytes_to_send = patterns;
            #3.251ns;
            group_start = $realtime;
            fork
                traffic.start(uart.sequencer);
                begin
                    foreach (patterns[i]) sample_driver(patterns[i], period, 0, 0, 0,
                        group_start + i * period * (1 + width + stops + (parity != 0)));
                end
                begin
                    foreach (patterns[i]) reference_send(patterns[i], period);
                end
                check_decoded(patterns);
            join
        end
    endtask

    task driver_injection_check();
        uart_rx_sequence traffic;
        uart_transaction observed;
        for (int width = 5; width <= 8; width += 3)
            for (int parity = 0; parity < 3; parity++)
                for (int stop_index = 0; stop_index < 2; stop_index++) begin
            cfg.data_width = width;
            cfg.parity_mode = uart_parity_e'(parity);
            cfg.num_of_stop_bit = 2;
            cfg.programmed_period = 160ns;
            traffic = uart_rx_sequence::type_id::create("driver_injected_frame");
            traffic.cfg = cfg;
            traffic.bytes_to_send = '{8'ha6};
            traffic.bad_parity = 1;
            traffic.bad_stop = 1;
            traffic.bad_stop_index = stop_index;
            fork
                traffic.start(uart.sequencer);
                sample_driver(8'ha6, 160ns, 1, 1, stop_index);
            join
            serial_frames.get(observed);
            if (observed.direction != UART_TX || observed.data != (8'ha6 & (8'hff >> (8 - width))) ||
                observed.inject_parity_error != (parity != 0) || !observed.inject_stop_error)
                `uvm_error("VIP_DRIVER_INJECTION", "Injected input frame decoded incorrectly")
            decoded_frames++;
            #1ns;
        end
    endtask

    task baud_fallback_check();
        uart_rx_sequence traffic;
        byte unsigned patterns[$] = '{8'h55, 8'ha6};
        cfg.data_width = 8;
        cfg.parity_mode = UART_PARITY_ODD;
        cfg.num_of_stop_bit = 2;
        cfg.baud_rate = 115200;
        cfg.programmed_period = 0;
        traffic = uart_rx_sequence::type_id::create("baud_fallback");
        traffic.cfg = cfg;
        traffic.bytes_to_send = patterns;
        fork
            traffic.start(uart.sequencer);
            begin
                foreach (patterns[i]) sample_driver(patterns[i], 8680.556ns);
            end
            begin
                foreach (patterns[i]) reference_send(patterns[i], 8680.556ns);
            end
            check_decoded(patterns);
        join
    endtask

    task monitor_negative(string id, bit bad_parity, bit bad_stop, bit glitch, int count);
        uart_error_catcher catcher;
        uart_transaction observed;
        catcher = new("expected_checker_error");
        catcher.expected_reporter = uart.monitor;
        catcher.expected_id = id;
        catcher.expected_count = count;
        if ($test$plusargs("VIP_CATCH_MISSING") && id == "UART_FRAME") catcher.expected_count++;
        uvm_report_cb::add(uart.monitor, catcher);
        reference_send(8'hff, 160ns, bad_parity, bad_stop, glitch);
        serial_frames.get(observed);
        if (observed.inject_parity_error != bad_parity || observed.inject_stop_error != bad_stop)
            `uvm_error("VIP_NEGATIVE_DECODE", "Monitor did not identify the injected frame error")
        if ($test$plusargs("VIP_CATCH_WRONG_ID") && id == "UART_FRAME")
            uart.monitor.uvm_report_error("UNEXPECTED_ID", "Must remain an error", UVM_NONE);
        if ($test$plusargs("VIP_CATCH_WRONG_COMPONENT") && id == "UART_FRAME")
            uvm_report_error(id, "Must remain an error from another component", UVM_NONE);
        if ($test$plusargs("VIP_CATCH_EXCESS") && id == "UART_FRAME")
            uart.monitor.uvm_report_error(id, "Excess error must remain an error", UVM_NONE);
        uvm_report_cb::delete(uart.monitor, catcher);
        catcher.check_count();
        decoded_frames++;
        #1ns;
    endtask

    task uart_reset_check();
        uart_rx_sequence traffic;
        uart_transaction observed;
        cfg.data_width = 8;
        cfg.parity_mode = UART_PARITY_EVEN;
        cfg.num_of_stop_bit = 2;
        cfg.programmed_period = 160ns;
        traffic = uart_rx_sequence::type_id::create("aborted_frame");
        traffic.cfg = cfg;
        traffic.bytes_to_send = '{8'ha6};
        fork
            traffic.start(uart.sequencer);
            begin
                fork : aborted_reference
                    reference_send(8'ha6, 160ns);
                    begin
                        @(negedge cfg.reset_n);
                    end
                join_any
                disable aborted_reference;
                uvif.rx = 1;
            end
            begin
                #400ns;
                @(negedge avif.HCLK);
                avif.HRESETn = 0;
                repeat (5) @(negedge avif.HCLK);
                avif.HRESETn = 1;
            end
        join
        #1ns;
        if (uvif.tx !== 1 || serial_frames.used() != 0)
            `uvm_error("VIP_RESET", "Aborted frame was published, or driver did not return to idle")
        // Prove the driver and both monitor threads resume after reset.
        fork
            traffic.start(uart.sequencer);
            sample_driver(8'ha6, 160ns);
            reference_send(8'ha6, 160ns);
            check_decoded(traffic.bytes_to_send);
        join
    endtask

    task ahb_pipeline_check();
        uart_ahb_sequence traffic;
        ahb_transaction frame, request, response;
        bit [31:0] model[8] = '{default:0};
        bit [31:0] expected_data;
        int expected_waits;
        bit expected_error;
        traffic = uart_ahb_sequence::type_id::create("reference_slave_traffic");
        repeat (3) begin
            for (int i = 0; i < 8; i++) traffic.add(1, 10'(4 * i), 32'h1937_c5a0^(32'(i) * 32'h0102_0408), i % 2);
            for (int i = 7; i >= 0; i--) traffic.add(0, 10'(4 * i), 0, i % 2);
            // ERROR followed immediately by legal transfers must preserve order.
            traffic.add(1, 10'h020, 32'habcd_1234);
            traffic.add(1, 10'h000, 32'h55aa_f00d);
            traffic.add(0, 10'h3fc, 0, 1);
            traffic.add(0, 10'h000);
        end
        traffic.start(ahb.sequencer);
        if (traffic.responses.size() != traffic.transfers.size())
            `uvm_fatal("VIP_AHB_COUNT", "Missing AHB driver response")
        foreach (traffic.transfers[i]) begin
            request = traffic.transfers[i];
            response = traffic.responses[i];
            bus_transfers.get(frame);
            expected_error = request.addr >= 10'h020;
            case (request.addr[3:2])
                0: expected_waits = 0;
                1: expected_waits = 1;
                2: expected_waits = 3;
                3: expected_waits = 7;
            endcase
            if (expected_error) expected_waits = 3;
            if (request.xact_type == ahb_transaction::WRITE && !expected_error)
                model[request.addr[4:2]] = request.data;
            expected_data = expected_error ? 32'hdead_beef : model[request.addr[4:2]];
            if (!response.completed || response.hresp !== expected_error || response.addr != request.addr ||
                frame.addr != request.addr || frame.xact_type != request.xact_type ||
                frame.burst_type != request.burst_type || frame.hresp !== expected_error ||
                !frame.completed || frame.wait_cycles != expected_waits ||
                (request.xact_type == ahb_transaction::READ &&
                (frame.rdata !== expected_data || response.rdata !== expected_data)) ||
                (request.xact_type == ahb_transaction::WRITE && frame.data !== request.data))
                `uvm_error("VIP_AHB_REFERENCE",
                    $sformatf("transfer=%0d addr=%03h wait=%0d expected_wait=%0d response=%b",
                        
                i, request.addr, frame.wait_cycles, expected_waits, response.hresp))
            checked_transfers++;
        end
    endtask

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        fork
            forever begin
                cfg.reset_n = avif.HRESETn;
                @(avif.HRESETn);
            end
        join_none
        fork : audit_timeout
            begin
                #20ms;
                `uvm_fatal("VIP_CHECK_TIMEOUT",
                    $sformatf("sampled=%0d decoded=%0d AHB=%0d: VIP self-check did not complete",
                        
                    sampled_frames, decoded_frames, checked_transfers))
            end
            begin
                wait (avif.HRESETn === 1);
                #1ns;
                uart_matrix();
                driver_injection_check();
                baud_fallback_check();
                uart_reset_check();
                cfg.data_width = 8;
                cfg.parity_mode = UART_PARITY_EVEN;
                cfg.num_of_stop_bit = 2;
                cfg.programmed_period = 160ns;
                monitor_negative("UART_FRAME", 1, 0, 0, 1);
                monitor_negative("UART_FRAME", 0, 1, 0, 1);
                monitor_negative("UART_TIMING", 0, 0, 1, 2);
                ahb_pipeline_check();
                #1ns;
            end
        join_any
        disable audit_timeout;
        phase.drop_objection(this);
    endtask

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (serial_frames.used() != 0 || bus_transfers.used() != 0 || sampled_frames != 399 ||
            decoded_frames != 789 || checked_transfers != 60)
            `uvm_error("VIP_CHECK_COUNTS",
                $sformatf("sampled=%0d decoded=%0d AHB=%0d leftover_UART=%0d leftover_AHB=%0d",
                    
            sampled_frames, decoded_frames, checked_transfers, serial_frames.used(), bus_transfers.used()))
    endfunction

    function void report_phase(uvm_phase phase);
        uvm_report_server server = uvm_report_server::get_server();
        super.report_phase(phase);
        `uvm_info("VIP_CHECK_COUNTS", $sformatf("sampled=%0d decoded=%0d AHB=%0d",
            sampled_frames, decoded_frames, checked_transfers), UVM_NONE)
        if (server.get_severity_count(UVM_ERROR) == 0 && server.get_severity_count(UVM_FATAL) == 0)
            `uvm_info("TEST_RESULT", "TEST PASSED", UVM_NONE)
        else
            `uvm_info("TEST_RESULT", "TEST FAILED", UVM_NONE)
    endfunction
endclass
