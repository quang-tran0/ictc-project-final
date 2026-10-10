class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    uart_configuration cfg;
    virtual uart_if vif;
    uvm_analysis_port #(uart_transaction) analysis_port;

    covergroup uart_cg with function sample(
        int unsigned data_width,
        uart_parity_e parity_mode,
        int unsigned num_of_stop_bit,
        int unsigned baud_rate,
        uart_direction_e direction,
        logic [7:0] data,
        bit parity_error,
        bit stop_error
    );
        option.per_instance = 1;
        
        cp_data_width: coverpoint data_width {
            bins width_5 = {5}; bins width_6 = {6};
            bins width_7 = {7}; bins width_8 = {8};
        }
        
        cp_parity: coverpoint parity_mode;
        
        cp_stop_bits: coverpoint num_of_stop_bit {
            bins one = {1}; bins two = {2};
        }
        
        cp_baud: coverpoint baud_rate {
            bins b4800 = {4800}; bins b9600 = {9600};
            bins b19200 = {19200};
            bins b57600 = {57600}; bins b115200 = {115200};
            bins other = default;
        }
        
        cp_direction: coverpoint direction;
        
        cp_data: coverpoint data {
            bins zero = {8'h00}; bins ones = {8'hff};
            bins alternating_55 = {8'h55}; bins alternating_aa = {8'haa};
            bins other = default;
        }
        
        cp_parity_error: coverpoint parity_error;
        cp_stop_error: coverpoint stop_error;
        frame_format: cross cp_data_width, cp_parity, cp_stop_bits;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
        uart_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(uart_configuration)::get(this, "", "cfg", cfg))
            `uvm_fatal("UART_CFG", $sformatf("No configuration for %s", get_full_name()))
        if (cfg == null) `uvm_fatal("UART_CFG", "Null monitor configuration")
        if (!cfg.is_valid()) `uvm_fatal("UART_CFG", "Invalid monitor configuration")
        vif = cfg.vif;

        if (vif == null) `uvm_fatal("UART_VIF", $sformatf("No virtual interface for %s", get_full_name()))
    endfunction

    task run_phase(uvm_phase phase);
        fork
            monitor_line(UART_TX);
            monitor_line(UART_RX);
        join
    endtask

    function logic line_value(uart_direction_e direction);
        return direction == UART_TX ? vif.tx : vif.rx;
    endfunction

    task wait_for_start(uart_direction_e direction);
        if (direction == UART_TX)
            @(negedge vif.tx);
        else
            @(negedge vif.rx);
    endtask

    task sample_frame(
        uart_direction_e direction,
        uart_configuration frame_cfg,
        output uart_transaction item
    );
        logic parity_bit;
        realtime period = frame_cfg.bit_period();
        item = null;
        #(period / 2.0);
        if (line_value(direction) !== 1'b0)
        return;

        item = uart_transaction::type_id::create("item");
        item.direction = direction;
        item.data = '0;

        for (int unsigned bit_index = 0; bit_index < frame_cfg.data_width; bit_index++) begin
            #(period);
            item.data[bit_index] = line_value(direction);
        end

        item.parity_error = 1'b0;
        if (frame_cfg.parity_mode != UART_PARITY_NONE) begin
            #(period);
            parity_bit = ^item.data;

            if (frame_cfg.parity_mode == UART_PARITY_ODD) parity_bit = ~parity_bit;
            item.parity_error = line_value(direction) !== parity_bit;
        end

        item.stop_error = 1'b0;
        for (int unsigned stop_index = 0; stop_index < frame_cfg.num_of_stop_bit; stop_index++) begin
            #(period);
            if (line_value(direction) !== 1'b1) item.stop_error = 1'b1;
        end
        item.completed = 1;
        if ($isunknown(item.data))
            `uvm_error("UART_DATA", "Unknown UART data sampled")
    endtask

    task monitor_line(uart_direction_e direction);
        uart_transaction item;
        uart_configuration frame_cfg;
        realtime period;
        realtime previous_edge;
        realtime elapsed;
        realtime expected;
        realtime difference;
        real tolerance;
        int unsigned bit_count;
        bit baud_error;

        forever begin
            wait (cfg.reset_n === 1'b1);
            wait_for_start(direction);
            if (cfg.reset_n !== 1'b1) continue;
            if (!cfg.is_valid()) `uvm_fatal("UART_CFG", "Invalid frame configuration")
            $cast(frame_cfg, cfg.clone());
            period = frame_cfg.bit_period();
            tolerance = frame_cfg.baud_tolerance;
            item = null;
            previous_edge = $realtime;
            baud_error = 1'b0;
            
            fork
                sample_frame(direction, frame_cfg, item);
                begin
                    forever begin
                        if (direction == UART_TX) @(vif.tx);
                        else @(vif.rx);
                        
                        elapsed = $realtime - previous_edge;
                        previous_edge = $realtime;
                        
                        // Equal adjacent data bits do not create edges. Check integer
                        // multiples of the bit period, with tolerance and time rounding.
                        bit_count = $rtoi(elapsed / period + 0.5);
                        expected = bit_count * period;
                        difference = elapsed > expected ? elapsed - expected : expected - elapsed;

                        if (bit_count == 0 || difference > bit_count * (period * tolerance + 1ps)) begin
                            baud_error = 1'b1;
                        end
                    end
                end
                begin
                    wait (cfg.reset_n !== 1'b1);
                end
            join_any
            // Each TX/RX worker owns only its frame-local child processes.
            disable fork;
            if (item == null || cfg.reset_n !== 1'b1)
                continue;

            // Errors are observations, not assumptions about testcase intent.
            // Subscribers must check these flags even for nominal traffic.
            item.baud_error = baud_error;
            uart_cg.sample(frame_cfg.data_width, frame_cfg.parity_mode,
                           frame_cfg.num_of_stop_bit, int'(1s / period),
                           direction, item.data, item.parity_error, item.stop_error);
            analysis_port.write(item);
        end
    endtask
endclass
