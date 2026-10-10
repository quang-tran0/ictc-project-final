class ahb_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_monitor)
    ahb_configuration cfg;
    virtual ahb_if vif;
    uvm_analysis_port #(ahb_transaction) analysis_port;
    int unsigned completed_count, ignored_count, error_count;
    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(ahb_configuration)::get(this, "", "cfg", cfg) || cfg == null)
            `uvm_fatal("AHB_CFG", "Missing monitor configuration")
        vif = cfg.vif;
        if (vif == null) `uvm_fatal("AHB_VIF", "Null interface")
    endfunction
    task run_phase(uvm_phase phase);
        ahb_transaction pending;
        bit error_wait;
        forever begin
            @(vif.mon_cb);
            if (!vif.mon_cb.HRESETn) begin pending = null; error_wait = 0; end
            else begin
                if (pending != null) begin
                    if ($isunknown({vif.mon_cb.HREADYOUT, vif.mon_cb.HRESP}))
                        `uvm_error("AHB_X", "Unknown response during data phase")
                    if (vif.mon_cb.HRESP && !vif.mon_cb.HREADYOUT) error_wait = 1;
                    if (vif.mon_cb.HREADYOUT) begin
                        pending.data = vif.mon_cb.HWDATA;
                        pending.rdata = vif.mon_cb.HRDATA;
                        pending.resp = vif.mon_cb.HRESP;
                        if (pending.resp) begin
                            error_count++;
                            if (!error_wait) `uvm_error("AHB_ERROR_PHASE", "ERROR must include a wait cycle")
                        end
                        completed_count++;
                        analysis_port.write(pending);
                        pending = null;
                        error_wait = 0;
                    end else pending.wait_cycles++;
                end
                if (vif.mon_cb.HREADYOUT && vif.mon_cb.HSEL && vif.mon_cb.HTRANS[1]) begin
                    pending = ahb_transaction::type_id::create("observed");
                    pending.addr = vif.mon_cb.HADDR;
                    pending.kind = vif.mon_cb.HWRITE ? ahb_transaction::WRITE : ahb_transaction::READ;
                    pending.burst = ahb_transaction::burst_type_e'(vif.mon_cb.HBURST);
                    pending.htrans = ahb_transaction::htrans_type_e'(vif.mon_cb.HTRANS);
                    if (vif.mon_cb.HSIZE != 2 || vif.mon_cb.HADDR[1:0] != 0)
                        `uvm_error("AHB_LEGAL", "Testbench issued unsupported size/alignment")
                end else if (vif.mon_cb.HSEL && !vif.mon_cb.HTRANS[1]) ignored_count++;
            end
        end
    endtask
endclass
