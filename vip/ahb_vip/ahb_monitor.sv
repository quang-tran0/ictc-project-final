class ahb_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_monitor)

    ahb_configuration cfg;
    virtual ahb_if vif;
    uvm_analysis_port#(ahb_transaction) analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(ahb_configuration)::get(this, "", "cfg", cfg))
            `uvm_fatal("AHB_MONITOR", "Configuration not found in uvm_config_db")

        if (cfg == null) `uvm_fatal("AHB_MONITOR", "Configuration is null")
        if (cfg.vif == null) `uvm_fatal("AHB_MONITOR", "Virtual interface is null")

        vif = cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
        
    endtask
endclass