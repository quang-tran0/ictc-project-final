class uart_ahb_sequence extends uvm_sequence #(ahb_transaction);
    `uvm_object_utils(uart_ahb_sequence)
    ahb_transaction transfers[$], responses[$];

    function new(string name = "uart_ahb_sequence");
        super.new(name);
        set_response_queue_depth(-1);
    endfunction

    function void add(bit write, bit [9:0] addr, bit [31:0] data = 0,
        bit incr = 0, bit select = 1, bit [1:0] transfer = 2'b10);
        ahb_transaction t;
        t = ahb_transaction::type_id::create("request");
        t.xact_type = write ? ahb_transaction::WRITE : ahb_transaction::READ;
        t.addr = addr;
        t.data = data;
        t.select = select;
        t.transfer = transfer;
        t.burst_type = incr ? ahb_transaction::AHB_INCR : ahb_transaction::AHB_SINGLE;
        transfers.push_back(t);
    endfunction

    task body();
        ahb_transaction rsp;
        responses.delete();
        foreach (transfers[i]) begin
            start_item(transfers[i]);
            finish_item(transfers[i]);
        end
        foreach (transfers[i]) begin
            get_response(rsp);
            if (!rsp.completed)
                `uvm_error("AHB_ABORT", "AHB request aborted before completion")
            responses.push_back(rsp);
        end
        // Let passive completion subscribers finish in the same clock slot.
        #1ps;
    endtask

    function void add_random_write(bit [9:0] address, bit [31:0] write_mask);
        ahb_transaction t;
        t = ahb_transaction::type_id::create("random_write");
        if (!t.randomize() with {
            addr == local::address;
            xact_type == ahb_transaction::WRITE;
            burst_type == ahb_transaction::AHB_SINGLE;
            (data & ~local::write_mask) == 0;
        })
            `uvm_fatal("RAND_AHB", "Cannot solve legal random AHB write")
        transfers.push_back(t);
    endfunction
endclass
