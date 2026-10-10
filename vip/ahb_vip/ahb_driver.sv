class ahb_driver extends uvm_driver #(ahb_transaction);
    `uvm_component_utils(ahb_driver)
    ahb_configuration cfg;
    virtual ahb_if vif;
    // Bounded lookahead permits consecutive NONSEQ address phases, not bursts.
    mailbox #(ahb_transaction) requests = new(1);

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(ahb_configuration)::get(this, "", "cfg", cfg) || cfg == null)
            `uvm_fatal("AHB_CFG", "Driver configuration is missing/null")
        if (!cfg.is_valid()) `uvm_fatal("AHB_CFG", "Invalid driver configuration/interface")
        vif = cfg.vif;
    endfunction

    // get() accepts the request; put_response() alone reports completion.
    // Sequences MUST drain responses with get_response() before returning.
    task collect_requests();
        ahb_transaction item, snapshot;
        forever begin
            seq_item_port.get(item);
            if (item.addr[1:0] != 0 || item.xfer_size != ahb_transaction::SIZE_32BIT ||
                !(item.burst_type inside {ahb_transaction::AHB_SINGLE, ahb_transaction::AHB_INCR}))
                `uvm_fatal("AHB_REQUEST", "Expected aligned word SINGLE/one-beat INCR")
            $cast(snapshot, item.clone());
            snapshot.set_id_info(item);
            snapshot.completed = 0;
            snapshot.hresp = 1'bx;
            snapshot.rdata = 'x;
            requests.put(snapshot);
        end
    endtask

    task idle_address();
        vif.HSEL <= 0;
        vif.HTRANS <= 0;
        vif.HADDR <= 0;
        vif.HWRITE <= 0;
        vif.HSIZE <= ahb_transaction::SIZE_32BIT;
        vif.HBURST <= ahb_transaction::AHB_SINGLE;
        vif.HPROT <= 0;
        vif.HMASTLOCK <= 0;
    endtask

    // Sample on the active clock edge, before slave NBA updates. Drive only
    // with nonblocking assignments, so DUT and monitor see the previous cycle.
    task run_bus();
        ahb_transaction address_item, data_item;
        bit address_valid = 0;
        idle_address();
        vif.HWDATA <= 0;
        forever begin
            @(posedge vif.HCLK or negedge vif.HRESETn);
            if (vif.HRESETn !== 1'b1) begin
                // Preserve response order and return each in-flight request once.
                if (data_item != null) seq_item_port.put_response(data_item);
                if (address_item != null) seq_item_port.put_response(address_item);
                data_item = null;
                address_item = null;
                address_valid = 0;
                idle_address();
                vif.HWDATA <= 0;
                continue;
            end
            if (vif.HREADYOUT !== 1'b1) begin
                // A two-cycle ERROR permits cancellation of the next address.
                // Retain that request and re-present it after the ERROR completes.
                if (vif.HRESP === 1'b1) begin
                    idle_address();
                    address_valid = 0;
                end
                continue;
            end

            if (data_item != null) begin
                data_item.completed = 1;
                data_item.hresp = vif.HRESP;
                if (data_item.xact_type == ahb_transaction::READ)
                    data_item.rdata = vif.HRDATA;
                seq_item_port.put_response(data_item);
                data_item = null;
            end
            // The previously driven address was accepted at this same edge.
            if (address_valid) begin
                data_item = address_item;
                address_item = null;
            end
            vif.HWDATA <= data_item == null ? 32'b0 : data_item.data;

            if (address_item == null) void'(requests.try_get(address_item));
            address_valid = address_item != null;
            if (address_valid) begin
                vif.HADDR <= address_item.addr;
                vif.HWRITE <= address_item.xact_type;
                vif.HSIZE <= address_item.xfer_size;
                vif.HBURST <= address_item.burst_type;
                vif.HSEL <= 1;
                vif.HTRANS <= 2'b10;
            end else idle_address();
        end
    endtask

    task run_phase(uvm_phase phase);
        fork
            collect_requests();
            run_bus();
        join
    endtask
endclass
