class uart_driver extends uvm_driver #(uart_transaction);
    `uvm_component_utils(uart_driver)
    uart_configuration cfg;
    virtual uart_if vif;
    int unsigned sent_count;
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(uart_configuration)::get(this, "", "cfg", cfg) || cfg == null)
            `uvm_fatal("UART_CFG", "Missing driver configuration")
        vif = cfg.vif;
        if (!cfg.is_valid()) `uvm_fatal("UART_CFG", "Invalid UART configuration")
    endfunction
    task drive_frame(uart_transaction item);
        bit p;
        time bt;
        bt = cfg.bit_period();
        p = (cfg.parity == uart_configuration::UART_PARITY_ODD);
        vif.tx = 0; #(bt);
        for (int i=0; i<cfg.data_width; i++) begin
            vif.tx = item.data[i]; p ^= item.data[i]; #(bt);
        end
        if (cfg.parity != uart_configuration::UART_PARITY_NONE) begin
            vif.tx = p ^ item.inject_parity_error; #(bt);
        end
        vif.tx = 1;
        repeat (cfg.num_of_stop_bits) #(bt);
        sent_count++;
    endtask
    task run_phase(uvm_phase phase);
        vif.tx = 1;
        forever begin
            seq_item_port.get_next_item(req);
            wait (vif.reset_n === 1);
            if (!cfg.is_valid()) `uvm_fatal("UART_CFG", "Invalid frame configuration")
            fork : frame_or_reset
                drive_frame(req);
                begin @(negedge vif.reset_n); end
            join_any
            disable frame_or_reset;
            vif.tx = 1;
            seq_item_port.item_done();
        end
    endtask
endclass
