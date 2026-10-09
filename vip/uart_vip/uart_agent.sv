class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)

    uart_configuration cfg;
    uart_monitor monitor;
    uart_driver driver;
    uart_sequencer sequencer;

    function new(string name="uart_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(uart_configuration)::get(this, "", "cfg", cfg))
            `uvm_fatal("UART_AGENT", "Configuration not found in uvm_config_db")

        if (cfg == null) `uvm_fatal("UART_AGENT", "Configuration is null")
        if (cfg.vif == null) `uvm_fatal("UART_AGENT", "Virtual interface is null")

        uvm_config_db#(uart_configuration)::set(this, "monitor", "cfg", cfg);
        monitor = uart_monitor::type_id::create("monitor", this);

        if (cfg.is_active == UVM_ACTIVE) begin
            uvm_config_db#(uart_configuration)::set(this, "driver", "cfg", cfg);
            driver = uart_driver::type_id::create("driver", this);
            sequencer = uart_sequencer::type_id::create("sequencer", this);
        end
    endfunction
endclass