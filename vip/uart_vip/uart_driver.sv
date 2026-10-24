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
        if (!uvm_config_db#(uart_configuration)::get(this, "", "cfg", cfg) || cfg == null)
            `uvm_fatal("UART_CFG", "Missing UART driver configuration")
        if (!cfg.is_valid())
            `uvm_fatal("UART_CFG", "Invalid UART configuration")
        vif = cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
        vif.tx = 1;
        forever begin
            seq_item_port.get_next_item(req);
            wait (cfg.reset_n === 1'b1);
            if (req.direction != UART_TX)
                `uvm_fatal("UART_DIR", "Driver only drives DUT RX")
            fork : active_frame
                drive_frame(req);
                begin
                    @(negedge cfg.reset_n);
                end
            join_any
            disable active_frame;
            vif.tx = 1;
            seq_item_port.item_done();
        end
    endtask

    task drive_frame(uart_transaction item);
        uart_transaction snapshot;
        bit parity_bit;
        realtime period;
        int width, stops;
        uart_parity_e parity;
        width = cfg.data_width;
        stops = cfg.num_of_stop_bit;
        parity = cfg.parity_mode;
        period = cfg.bit_period();
        $cast(snapshot, item.clone());
        snapshot.data &= 8'hff >> (8 - width);
        snapshot.inject_parity_error &= parity != UART_PARITY_NONE;
        snapshot.data_width = width;
        snapshot.stop_bits = stops;
        snapshot.parity_mode = int'(parity);
        snapshot.period = period;
        snapshot.oversampling = cfg.oversampling;
        request_ap.write(snapshot);
        parity_bit = ^snapshot.data;
        if (parity == UART_PARITY_ODD) parity_bit = ~parity_bit;
        if (snapshot.inject_parity_error) parity_bit = ~parity_bit;
        vif.tx = 0;
        #(period);
        for (int i = 0; i < width; i++) begin
            vif.tx = snapshot.data[i];
            #(period);
        end
        if (parity != UART_PARITY_NONE) begin
            vif.tx = parity_bit;
            #(period);
        end
        for (int i = 0; i < stops; i++) begin
            vif.tx = (snapshot.inject_stop_error && i == snapshot.stop_error_index) ? 0 : 1;
            #(period);
        end
        vif.tx = 1;
    endtask
endclass
