class ahb_driver extends uvm_driver#(ahb_transaction);
    `uvm_component_utils(ahb_driver)

    ahb_configuration cfg;
    virtual ahb_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(ahb_configuration)::get(this, "", "cfg", cfg))
            `uvm_fatal("AHB_DRIVER", "Configuration not found in uvm_config_db")

        if (cfg == null) `uvm_fatal("AHB_DRIVER", "Configuration is null")
        if (cfg.vif == null) `uvm_fatal("AHB_DRIVER", "Virtual interface is null")

        vif = cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
    
    endtask
endclass