class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)
    uart_configuration cfg;
    bit decoding[2];
    virtual uart_if vif;
    uvm_analysis_port #(uart_transaction) analysis_port;
    function new(string name, uvm_component parent);
        super.new(name, parent); analysis_port = new("analysis_port", this);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(uart_configuration)::get(this, "", "cfg", cfg) || cfg == null)
            `uvm_fatal("UART_CFG", "Missing monitor configuration")
        vif = cfg.vif;
        if (!cfg.is_valid()) `uvm_fatal("UART_CFG", "Invalid UART configuration")
    endfunction
    function logic pin(bit dut_tx); return dut_tx ? vif.rx : vif.tx; endfunction
    task decode(bit dut_tx);
        uart_transaction item;
        time bt;
        bit p;
        forever begin
            if (dut_tx) @(negedge vif.rx); else @(negedge vif.tx);
            if (vif.reset_n !== 1) continue;
            decoding[dut_tx]=1;
            item = uart_transaction::type_id::create("frame");
            item.direction = dut_tx ? uart_transaction::UART_TX : uart_transaction::UART_RX;
            item.start_time = $time;
            item.data_width = cfg.data_width; item.parity_mode = cfg.parity;
            item.stop_bits = cfg.num_of_stop_bits; item.divisor = cfg.divisor; item.osm_sel = cfg.osm_sel;
            bt = cfg.bit_period();
            p = (cfg.parity == uart_configuration::UART_PARITY_ODD);
            fork
                begin
                    #(bt/2);
                    if (pin(dut_tx) === 0) begin
                        for (int i=0; i<item.data_width; i++) begin
                            #(bt);
                            if ($isunknown(pin(dut_tx))) `uvm_error("UART_X", "Unknown serial data")
                            item.data[i] = pin(dut_tx); p ^= item.data[i];
                        end
                        if (item.parity_mode != uart_configuration::UART_PARITY_NONE) begin
                            #(bt); item.parity_error = (pin(dut_tx) !== p);
                        end
                        repeat (item.stop_bits) begin
                            #(bt); if (pin(dut_tx) !== 1) item.stop_error = 1;
                        end
                        analysis_port.write(item);
                    end
                end
                begin @(negedge vif.reset_n); end
            join_any
            disable fork; // Only this decoder invocation; TX and RX run concurrently.
            decoding[dut_tx]=0;
        end
    endtask
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if(decoding[1]) `uvm_error("UART_TX_INCOMPLETE","Test ended with an unfinished TX frame")
        if(decoding[0]) `uvm_error("UART_RX_INCOMPLETE","Test ended with an unfinished RX frame")
    endfunction
    task run_phase(uvm_phase phase);
        fork decode(1); decode(0); join
    endtask
endclass
