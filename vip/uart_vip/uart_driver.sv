class uart_driver extends uvm_driver#(uart_transaction);
    `uvm_component_utils(uart_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(uart_configuration)::get(this, "", "cfg", cfg))
            `uvm_fatal("UART_DRIVER", "Configuration not found in uvm_config_db")

        if (cfg == null) `uvm_fatal("UART_DRIVER", "Configuration is null")
        if (cfg.vif == null) `uvm_fatal("UART_DRIVER", "Virtual interface is null")

        vif = cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);

    endtask
endclass