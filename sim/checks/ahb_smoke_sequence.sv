class ahb_smoke_sequence extends uvm_sequence #(ahb_transaction);
    `uvm_object_utils(ahb_smoke_sequence)
    ahb_transaction items[$];
    ahb_transaction responses[$];
`ifdef VIP_USE_DUT
    // uart_top ties the bridge HREADY input high: overlapping transfers are a
    // separately reproducible DUT integration failure, not a VIP workaround.
    bit pipeline = 0;
`else
    bit pipeline = 1;
`endif

    function new(string name = "ahb_smoke_sequence");
        super.new(name);
        set_response_queue_depth(-1);
    endfunction

    task body();
        ahb_transaction response;
        if ($test$plusargs("AHB_PIPELINE")) pipeline = 1;
        // Queue independent SINGLE transfers to exercise address/data overlap.
        foreach (items[i]) begin
            start_item(items[i]);
            finish_item(items[i]);
            if (!pipeline) begin
                get_response(response);
                responses.push_back(response);
            end
        end
        // get/put contract: sending a request is not bus completion.
        if (pipeline) foreach (items[i]) begin
            get_response(response);
            responses.push_back(response);
        end
    endtask
endclass
