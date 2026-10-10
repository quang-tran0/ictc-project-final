class ahb_driver extends uvm_driver #(ahb_transaction);
    `uvm_component_utils(ahb_driver)
    ahb_configuration cfg;
    virtual ahb_if vif;
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(ahb_configuration)::get(this, "", "cfg", cfg) || cfg == null)
            `uvm_fatal("AHB_CFG", "Missing driver configuration")
        vif = cfg.vif;
        if (vif == null) `uvm_fatal("AHB_VIF", "Null interface")
    endfunction
    task idle();
        vif.HSEL = 0; vif.HTRANS = 0; vif.HADDR = 0; vif.HWRITE = 0;
        vif.HBURST = 0; vif.HSIZE = 2; vif.HPROT = 0; vif.HMASTLOCK = 0;
        vif.HWDATA = 0;
    endtask
    task run_phase(uvm_phase phase);
        idle();
        forever begin
            seq_item_port.get_next_item(req);
            wait (vif.HRESETn === 1);
            @(negedge vif.HCLK);
            vif.HADDR = req.addr; vif.HWRITE = (req.kind == ahb_transaction::WRITE);
            vif.HBURST = req.burst; vif.HSEL = req.selected; vif.HTRANS = req.htrans;
            @(posedge vif.HCLK); // Address phase accepted; no previous transfer pending.
            @(negedge vif.HCLK);
            vif.HSEL = 0; vif.HTRANS = 0; vif.HWDATA = req.data;
            req.wait_cycles = 0;
            if (req.selected && req.htrans[1]) begin
                do begin
                    @(vif.mon_cb);
                    req.wait_cycles++;
                    if (!vif.mon_cb.HRESETn) `uvm_fatal("AHB_RESET", "Reset during active bus transfer")
                    if (req.wait_cycles > cfg.timeout_cycles)
                        `uvm_fatal("AHB_TIMEOUT", $sformatf("addr=%03h", req.addr))
                end while (vif.mon_cb.HREADYOUT !== 1);
                req.rdata = vif.mon_cb.HRDATA;
                req.resp = vif.mon_cb.HRESP;
            end else @(vif.mon_cb);
            seq_item_port.item_done();
        end
    endtask
endclass
