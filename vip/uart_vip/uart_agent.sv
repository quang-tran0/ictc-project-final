class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)

    uart_configuration cfg;
    uart_monitor monitor;
    uart_driver driver;
    uart_sequencer sequencer;
    uvm_analysis_port #(uart_transaction) monitor_ap;
    uvm_analysis_port #(uart_transaction) driver_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        monitor_ap = new("monitor_ap", this);
        driver_ap = new("driver_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(uart_configuration)::get(this, "", "cfg", cfg))
        `uvm_fatal("UART_CFG", $sformatf("No configuration for %s", get_full_name()))
        if (!cfg.is_valid())
        `uvm_fatal("UART_CFG", $sformatf("Invalid UART configuration: %s", cfg.sprint()))
        if (cfg.vif == null)
        `uvm_fatal("UART_VIF", $sformatf("No virtual interface for %s", get_full_name()))

        uvm_config_db #(uart_configuration)::set(this, "monitor", "cfg", cfg);
        monitor = uart_monitor::type_id::create("monitor", this);

        if (cfg.is_active == UVM_ACTIVE) begin
        uvm_config_db #(uart_configuration)::set(this, "driver", "cfg", cfg);
        driver = uart_driver::type_id::create("driver", this);
        sequencer = uart_sequencer::type_id::create("sequencer", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor.analysis_port.connect(monitor_ap);
        if (cfg.is_active == UVM_ACTIVE) begin
        driver.seq_item_port.connect(sequencer.seq_item_export);
        driver.request_ap.connect(driver_ap);
        end
    endfunction
endclass
