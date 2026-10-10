class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    uart_configuration cfg;
    virtual uart_if vif;
    uvm_analysis_port#(uart_transaction) analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(uart_configuration)::get(this, "", "cfg", cfg))
            `uvm_fatal("UART_MONITOR", "Configuration not found in uvm_config_db")

        if (cfg == null) `uvm_fatal("UART_MONITOR", "Configuration is null")
        if (cfg.vif == null) `uvm_fatal("UART_MONITOR", "Virtual interface is null")

        vif = cfg.vif;
        analysis_port = new("analysis_port", this);
    endfunction

    task run_phase(uvm_phase phase);

    endtask
endclass