class uart_driver extends uvm_driver #(uart_transaction);
    `uvm_component_utils(uart_driver)

    uart_configuration cfg;
    virtual uart_if vif;
    uvm_analysis_port #(uart_transaction) request_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        request_ap = new("request_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(uart_configuration)::get(this, "", "cfg", cfg))
            `uvm_fatal("UART_CFG", $sformatf("No configuration for %s", get_full_name()))
            vif = cfg.vif;
        if (vif == null)
            `uvm_fatal("UART_VIF", $sformatf("No virtual interface for %s", get_full_name()))
    endfunction

    task run_phase(uvm_phase phase);
        realtime idle_start;
        realtime remaining_idle;
        bit first_tx = 1'b1;

        vif.tx = 1'b1;
        idle_start = $realtime;
        #(cfg.bit_period());
        forever begin
        seq_item_port.get_next_item(req);
        if (req.direction == UART_TX) begin
            // The test may randomize the initial baud while get_next_item waits.
            // Complete one idle bit at the configuration used by the first frame.
            if (first_tx) begin
                remaining_idle = cfg.bit_period() - ($realtime - idle_start);
                if (remaining_idle > 0.0)
                    #(remaining_idle);
                first_tx = 1'b0;
            end

            publish_request(req);
            drive_frame(req);
        end
        else begin
            `uvm_warning("UART_DIR", "UART_RX items are captured automatically by the monitor")
        end
        seq_item_port.item_done();
        end
    endtask

    function bit [8:0] data_mask();
        return 9'h1ff >> (9 - cfg.data_width);
    endfunction

    function void publish_request(uart_transaction item);
        uart_transaction normalized;
        $cast(normalized, item.clone());
        normalized.data &= data_mask();

        if (cfg.parity_mode == UART_PARITY_NONE)
            normalized.inject_parity_error = 1'b0;
            
        request_ap.write(normalized);
    endfunction

    task drive_frame(uart_transaction item);
        bit parity_bit;
        realtime period;

        period = cfg.bit_period();
        parity_bit = ^(item.data & data_mask());
        if (cfg.parity_mode == UART_PARITY_ODD)
        parity_bit = ~parity_bit;
        if (item.inject_parity_error)
        parity_bit = ~parity_bit;

        vif.tx = 1'b0;
        #(period);

        for (int unsigned bit_index = 0; bit_index < cfg.data_width; bit_index++) begin
        vif.tx = item.data[bit_index];
        #(period);
        end

        if (cfg.parity_mode != UART_PARITY_NONE) begin
        vif.tx = parity_bit;
        #(period);
        end

        for (int unsigned stop_index = 0;
            stop_index < cfg.num_of_stop_bit;
            stop_index++) begin
        vif.tx = item.inject_stop_error &&
                (stop_index == item.stop_error_index) ? 1'b0 : 1'b1;
        #(period);
        end

        vif.tx = 1'b1;
    endtask
endclass
