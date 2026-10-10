class ahb_agent extends uvm_agent;
    `uvm_component_utils(ahb_agent)

    ahb_configuration cfg;
    ahb_monitor monitor;
    ahb_driver driver;
    ahb_sequencer sequencer;
    uvm_analysis_port #(ahb_transaction) monitor_ap;

    function new(string name="ahb_agent", uvm_component parent);
        super.new(name, parent);
        monitor_ap = new("monitor_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(ahb_configuration)::get(this, "", "cfg", cfg))
            `uvm_fatal("AHB_AGENT", "Configuration not found in uvm_config_db")

        if (cfg == null) `uvm_fatal("AHB_AGENT", "Configuration is null")
        if (!cfg.is_valid()) `uvm_fatal("AHB_AGENT", "Invalid configuration/interface")
        is_active = cfg.is_active;

        uvm_config_db#(ahb_configuration)::set(this, "monitor", "cfg", cfg);
        monitor = ahb_monitor::type_id::create("monitor", this);

        if (cfg.is_active == UVM_ACTIVE) begin
            uvm_config_db#(ahb_configuration)::set(this, "driver", "cfg", cfg);
            uvm_config_db#(ahb_configuration)::set(this, "sequencer", "cfg", cfg);
            driver = ahb_driver::type_id::create("driver", this);
            sequencer = ahb_sequencer::type_id::create("sequencer", this);
        end
    endfunction
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor.analysis_port.connect(monitor_ap);
        if (cfg.is_active == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
