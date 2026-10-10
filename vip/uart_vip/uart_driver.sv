class uart_driver extends uvm_driver #(uart_transaction);
    `uvm_component_utils(uart_driver)
    uart_configuration cfg;
    virtual uart_if vif;
    uvm_analysis_port #(uart_transaction) request_ap;
    bit need_idle = 1;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        request_ap = new("request_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(uart_configuration)::get(this, "", "cfg", cfg) || cfg == null)
            `uvm_fatal("UART_CFG", "Driver configuration is missing/null")
        if (!cfg.is_valid()) `uvm_fatal("UART_CFG", "Invalid UART configuration")
        vif = cfg.vif;
        if (vif == null) `uvm_fatal("UART_VIF", "No driver virtual interface")
    endfunction

    task transmit_items();
        uart_configuration frame_cfg;
        uart_transaction normalized;
        bit finished;
        forever begin
            seq_item_port.get_next_item(req);
            req.completed = 0;
            if (req.direction != UART_TX)
                `uvm_fatal("UART_DIR", "Driver accepts VIP TX items only; RX is monitored")
            wait (cfg.reset_n === 1'b1);
            if (!cfg.is_valid()) `uvm_fatal("UART_CFG", "Invalid frame configuration")
            $cast(frame_cfg, cfg.clone());
            if (req.inject_stop_error && req.stop_error_index >= frame_cfg.num_of_stop_bit)
                `uvm_fatal("UART_STOP", "stop_error_index is outside configured stop bits")
            $cast(normalized, req.clone());
            normalized.data &= 8'hff >> (8 - frame_cfg.data_width);
            if (frame_cfg.parity_mode == UART_PARITY_NONE)
                normalized.inject_parity_error = 0;
            finished = 0;
            fork
                begin
                    // One idle bit on initialization/reset, none inserted between frames.
                    if (need_idle) #(frame_cfg.bit_period());
                    request_ap.write(normalized);
                    drive_frame(normalized, frame_cfg);
                    finished = 1;
                end
                begin
                    wait (cfg.reset_n !== 1'b1);
                end
            join_any
            disable fork;
            vif.tx = 1;
            req.completed = finished && cfg.reset_n === 1'b1;
            need_idle = !req.completed;
            seq_item_port.item_done();
        end
    endtask

    task run_phase(uvm_phase phase);
        vif.tx = 1;
        fork
            transmit_items();
            forever begin
                @(negedge cfg.reset_n);
                need_idle = 1;
            end
        join
    endtask

    task drive_frame(uart_transaction item, uart_configuration frame_cfg);
        bit parity_bit;
        realtime period;
        period = frame_cfg.bit_period();
        parity_bit = ^item.data;
        if (frame_cfg.parity_mode == UART_PARITY_ODD) parity_bit = ~parity_bit;
        if (item.inject_parity_error) parity_bit = ~parity_bit;

        vif.tx = 0;
        #(period);
        for (int unsigned bit_index = 0; bit_index < frame_cfg.data_width; bit_index++) begin
            vif.tx = item.data[bit_index];
            #(period);
        end
        if (frame_cfg.parity_mode != UART_PARITY_NONE) begin
            vif.tx = parity_bit;
            #(period);
        end
        for (int unsigned stop_index = 0; stop_index < frame_cfg.num_of_stop_bit; stop_index++) begin
            vif.tx = item.inject_stop_error && stop_index == item.stop_error_index ? 0 : 1;
            #(period);
        end
        vif.tx = 1;
    endtask
endclass
