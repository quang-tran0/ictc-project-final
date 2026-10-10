class ahb_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_monitor)
    ahb_configuration cfg;
    virtual ahb_if vif;
    uvm_analysis_port #(ahb_transaction) analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(ahb_configuration)::get(this, "", "cfg", cfg) || cfg == null)
            `uvm_fatal("AHB_CFG", "Monitor configuration is missing/null")
        if (!cfg.is_valid()) `uvm_fatal("AHB_CFG", "Invalid monitor configuration/interface")
        vif = cfg.vif;
    endfunction

    // Passive active-region sampling precedes driver/slave NBA updates.
    task run_phase(uvm_phase phase);
        ahb_transaction pending;
        forever begin
            @(posedge vif.HCLK or negedge vif.HRESETn);
            if (vif.HRESETn !== 1'b1) begin
                pending = null;
                continue;
            end
            if (vif.HREADYOUT !== 1'b1) continue;
            // Complete the old data phase BEFORE capturing the next address.
            if (pending != null) begin
                if (pending.xact_type == ahb_transaction::WRITE)
                    pending.data = vif.HWDATA;
                else pending.rdata = vif.HRDATA;
                pending.hresp = vif.HRESP;
                pending.completed = 1;
                analysis_port.write(pending);
                pending = null;
            end
            if (vif.HSEL === 1'b1 && vif.HTRANS[1] === 1'b1) begin
                pending = ahb_transaction::type_id::create("observed");
                pending.addr = vif.HADDR;
                if (!$cast(pending.xact_type, vif.HWRITE) ||
                    !$cast(pending.xfer_size, vif.HSIZE) ||
                    !$cast(pending.burst_type, vif.HBURST))
                    `uvm_error("AHB_CONTROL", "Observed unsupported or unknown AHB control")
            end
        end
    endtask
endclass
