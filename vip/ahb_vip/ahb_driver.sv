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

    virtual task run_phase(uvm_phase phase);
        wait (ahb_vif.HRESETn === 1'b1);

        forever begin
            seq_item_port.get(req);

            `uvm_info(get_type_name(), $sformatf("Driver received request: \n %s", req.sprint()), UVM_LOW)

            drive(req);
            $cast(rsp, req.clone());
            rsp.set_id_info(req);
            seq_item_port.put(rsp);

            `uvm_info(
                get_type_name(),
                $sformatf("Driver sending response: \n %s", rsp.sprint()),
                UVM_LOW
            )
        end
    endtask: run_phase

    virtual task drive(inout ahb_transaction req);
        @(posedge ahb_vif.HCLK); #1ps;
        ahb_vif.HADDR = req.addr;
        ahb_vif.HBURST = req.burst_type;
        ahb_vif.HMASTLOCK = req.lock;
        ahb_vif.HPROT = req.prot;
        ahb_vif.HSIZE = req.xfer_size;
        ahb_vif.HTRANS = 2'b10;
        ahb_vif.HWRITE = req.xact_type;

        @(posedge ahb_vif.HCLK); #1ps;

        if (req.xact_type == ahb_transaction::WRITE) begin
            ahb_vif.HWDATA = req.data;
        end

        ahb_vif.HADDR = 'h0;
        ahb_vif.HBURST = 'h0;
        ahb_vif.HMASTLOCK = 'h0;
        ahb_vif.HPROT = 'h0;
        ahb_vif.HSIZE = 'h0;
        ahb_vif.HTRANS = 'h0;
        ahb_vif.HWRITE = 'h0;

        @(posedge ahb_vif.HREADYOUT);

        if (req.xact_type == ahb_transaction::READ) begin
            @(posedge ahb_vif.HCLK);
            req.data = ahb_vif.HRDATA;
        end
    endtask: drive
endclass