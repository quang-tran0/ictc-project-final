class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)
    uart_configuration cfg;
    virtual uart_if vif;
    uvm_analysis_port #(uart_transaction) analysis_port;
    int unsigned tx_frames, rx_frames;
    covergroup uart_cg with function sample(int width, int parity, int stops, int osm,
            uart_direction_e direction, bit [7:0] data, bit pe, bit se);
        option.per_instance = 1;
        cp_width: coverpoint width {
            bins widths[] = {[5:8]};
        }
        cp_parity: coverpoint parity {
            bins modes[] = {[0:2]};
        }
        cp_stops: coverpoint stops {
            bins counts[] = {[1:2]};
        }
        cp_osm: coverpoint osm {
            bins x13 = {13};
            bins x16 = {16};
        }
        cp_direction: coverpoint direction;
        cp_data: coverpoint data {
            bins zero = {0};
            bins ones = {255};
            bins alternating[] = {8'h55, 8'haa};
            bins other = default;
        }
        cp_error: coverpoint pe;
        cp_stop_error: coverpoint se;
        cp_payload_parity: coverpoint (^data) iff(parity != 0 && !pe && !se);
        frame_format: cross cp_width, cp_parity, cp_stops, cp_osm, cp_direction iff(!pe && !se);
        parity_values: cross cp_width, cp_parity, cp_osm, cp_direction, cp_payload_parity
            iff(!pe && !se) {
            ignore_bins parity_disabled = binsof(cp_parity) intersect {0};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
        uart_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(uart_configuration)::get(this, "", "cfg", cfg) || cfg == null)
            `uvm_fatal("UART_CFG", "Missing UART monitor configuration")
        vif = cfg.vif;
    endfunction

    function logic line_value(uart_direction_e d);
        return d == UART_TX ? vif.tx : vif.rx;
    endfunction

    task start_edge(uart_direction_e d);
        if (d == UART_TX) @(negedge vif.tx);
        else @(negedge vif.rx);
    endtask

    task run_phase(uvm_phase phase);
        fork
            monitor_line(UART_TX);
            monitor_line(UART_RX);
        join
    endtask

    task monitor_line(uart_direction_e d);
        forever begin
            start_edge(d);
            if (cfg.reset_n !== 1 || !cfg.monitor_enable) continue;
            // Cancel this direction only; the other monitor may still be active.
            fork
                capture(d);
                begin
                    @(negedge cfg.reset_n);
                end
            join_any
            disable fork;
        end
    endtask

    task capture(uart_direction_e d);
        uart_transaction item;
        bit parity_bit;
        realtime edge_offset, fraction, tolerance;
        item = uart_transaction::type_id::create("observed_frame");
        item.direction = d;
        item.period = cfg.bit_period();
        item.started_at = $realtime;
        item.data_width = cfg.data_width;
        item.stop_bits = cfg.num_of_stop_bit;
        item.parity_mode = int'(cfg.parity_mode);
        item.oversampling = cfg.oversampling;
        item.data = 0;
        fork
            begin
                #(item.period / 2.0);
                if (line_value(d) !== 0)
                    `uvm_error("UART_START", "Start bit not low at its midpoint")
                for (int i = 0; i < item.data_width; i++) begin
                    #(item.period);
                    if ($isunknown(line_value(d)))
                        `uvm_error("UART_X", "Unknown serial data bit")
                    item.data[i] = line_value(d);
                end
                if (item.parity_mode != int'(UART_PARITY_NONE)) begin
                    #(item.period);
                    parity_bit = ^item.data;
                    if (item.parity_mode == int'(UART_PARITY_ODD)) parity_bit = ~parity_bit;
                    item.inject_parity_error = line_value(d) !== parity_bit;
                end
                for (int i = 0; i < item.stop_bits; i++) begin
                    #(item.period);
                    if (line_value(d) !== 1) item.inject_stop_error = 1;
                end
                // Use an absolute deadline: two rounded half-bit delays can
                // otherwise finish on the next start edge and lose that frame.
                #(item.started_at + item.period * (1 + item.data_width + item.stop_bits+
                    (item.parity_mode != int'(UART_PARITY_NONE))) - $realtime - 1ps);
            end
            begin
                // Midpoint decoding alone can miss off-grid TX edges.
                forever begin
                    if (d == UART_TX) @(vif.tx);
                    else @(vif.rx);
                    edge_offset = ($realtime - item.started_at) / item.period;
                    fraction = edge_offset - $floor(edge_offset);
                    tolerance = 2ns / item.period;
                    if (fraction > tolerance && fraction < 1.0 - tolerance && d == UART_RX)
                        `uvm_error("UART_TIMING",
                            $sformatf("Off-grid TX edge at %0t, bit offset %0f",
                                $time, edge_offset))
                end
            end
        join_any
        disable fork;
        if (d == UART_RX && (item.inject_parity_error || item.inject_stop_error))
            `uvm_error("UART_FRAME",
                $sformatf("DUT TX data=%02h WLS=%0d parity_mode=%0d parity_error=%b stop_error=%b",
                    item.data, item.data_width, item.parity_mode, item.inject_parity_error, item.inject_stop_error))
        uart_cg.sample(item.data_width, item.parity_mode, item.stop_bits,
                       item.oversampling, d, item.data,
                       item.inject_parity_error, item.inject_stop_error);
        if (d == UART_RX) tx_frames++;
        else rx_frames++;
        analysis_port.write(item);
    endtask
endclass
