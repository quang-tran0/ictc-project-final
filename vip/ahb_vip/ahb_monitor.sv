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

    virtual task run_phase(uvm_phase phase);
        ahb_transaction obs_trans;
        wait(ahb_vif.HRESETn === 1'b1);

        forever begin
            @(posedge ahb_vif.HCLK);

            if (ahb_vif.HTRANS[1] === 1'b1) begin
                obs_trans = ahb_transaction::type_id::create("obs_trans");
                obs_trans.addr = ahb_vif.HADDR;
                obs_trans.prot = ahb_vif.HPROT;
                obs_trans.lock = ahb_vif.HMASTLOCK;

                if (!$cast(obs_trans.xact_type, ahb_vif.HWRITE))
                    `uvm_error(get_type_name(), $sformatf("Cannot convert HWRITE=%0b to xact_type", ahb_vif.HWRITE))
                if (!$cast(obs_trans.burst_type, ahb_vif.HBURST))
                    `uvm_error(get_type_name(), $sformatf("Cannot convert HBURST=%0b to xact_type", ahb_vif.HBURST))
                if (!$cast(obs_trans.xfer_size, ahb_vif.HSIZE))
                    `uvm_error(get_type_name(), $sformatf("Cannot convert HSIZE=%0b to xact_type", ahb_vif.HSIZE))

                @(posedge ahb_vif.HCLK); #1ps;

                if (obs_trans.xact_type === ahb_transaction::WRITE) begin
                    obs_trans.data = ahb_vif.HWDATA;
                end

                @(posedge ahb_vif.HREADYOUT);

                if (obs_trans.xact_type === ahb_transaction::READ) begin
                    obs_trans.data = ahb_vif.HRDATA;
                end

                if (ahb_vif.HRESP !== 1'b0)
                    `uvm_error(get_type_name(), $sformatf("Observed AHB error response at address 0x%0h", obs_trans.addr))

                item_observed_port.write(obs_trans);
            end
        end
    endtask: run_phase
endclass