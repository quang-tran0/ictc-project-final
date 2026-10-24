class ahb_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_monitor)
    ahb_configuration cfg;
    virtual ahb_if vif;
    uvm_analysis_port #(ahb_transaction) analysis_port;
    int unsigned read_wait_cycles, write_wait_cycles, completed_reads, completed_writes;
    covergroup ahb_cg with function sample(bit [9:0] addr, bit write, bit burst, bit error, int waits);
        option.per_instance = 1;
        cp_addr: coverpoint addr {
            bins registers[] = {'h000, 'h004, 'h008, 'h00c, 'h010, 'h014, 'h018, 'h01c};
            bins reserved_boundary[] = {'h020, 'h3fc};
            bins reserved_middle = {['h024:'h3f8]};
        }
        cp_write: coverpoint write;
        cp_burst: coverpoint burst;
        cp_error: coverpoint error;
        cp_waits: coverpoint waits {
            bins zero = {0};
            bins stalled = {[1:2000]};
        }
        transfer: cross cp_write, cp_burst, cp_error;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
        ahb_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(ahb_configuration)::get(this, "", "cfg", cfg) || cfg == null)
            `uvm_fatal("AHB_CFG", "Monitor configuration is missing/null")
        if (!cfg.is_valid())
            `uvm_fatal("AHB_CFG", "Invalid monitor configuration/interface")
        vif = cfg.vif;
    endfunction

    // Passive active-region sampling precedes driver/slave NBA updates.
    task run_phase(uvm_phase phase);
        ahb_transaction pending;
        logic [24:0] held_controls;
        logic [31:0] held_data;
        bit hold_required = 0, error_first_cycle = 0;
        forever begin
            @(posedge vif.HCLK or negedge vif.HRESETn);
            if (vif.HRESETn !== 1'b1) begin
                pending = null;
                hold_required = 0;
                error_first_cycle = 0;
                continue;
            end
            if (hold_required) begin
                if ({vif.HADDR, vif.HSIZE, vif.HBURST, vif.HWRITE, vif.HTRANS, vif.HSEL, vif.HPROT, vif.HMASTLOCK} !== held_controls)
                    `uvm_error("AHB_STALL_CONTROL", "Master changed address/control during wait state")
                if (pending != null && pending.xact_type == ahb_transaction::WRITE && vif.HWDATA !== held_data)
                    `uvm_error("AHB_STALL_DATA", "Master changed write data during wait state")
            end
            if (error_first_cycle && !(vif.HRESP === 1 && vif.HREADYOUT === 1))
                `uvm_error("AHB_ERROR_SEQUENCE", "ERROR response did not finish with HRESP1/HREADYOUT1")
            error_first_cycle = (vif.HRESP === 1 && vif.HREADYOUT === 0);
            hold_required = (vif.HREADYOUT === 0 && vif.HRESP !== 1);
            held_controls = {vif.HADDR, vif.HSIZE, vif.HBURST, vif.HWRITE, vif.HTRANS, vif.HSEL, vif.HPROT, vif.HMASTLOCK};
            held_data = vif.HWDATA;
            if (vif.HREADYOUT !== 1'b1) begin
                if (pending != null) begin
                    pending.wait_cycles++;
                    if (pending.xact_type == ahb_transaction::READ) read_wait_cycles++;
                    else write_wait_cycles++;
                end
                continue;
            end
            // Complete the old data phase BEFORE capturing the next address.
            if (pending != null) begin
                if (pending.xact_type == ahb_transaction::WRITE)
                    pending.data = vif.HWDATA;
                else pending.rdata = vif.HRDATA;
                pending.hresp = vif.HRESP;
                pending.completed = 1;
                ahb_cg.sample(pending.addr, pending.xact_type == ahb_transaction::WRITE,
                    pending.burst_type == ahb_transaction::AHB_INCR, pending.hresp, pending.wait_cycles);
                if (pending.xact_type == ahb_transaction::READ) completed_reads++;
                else completed_writes++;
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
