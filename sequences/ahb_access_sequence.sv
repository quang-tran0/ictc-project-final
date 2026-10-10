class ahb_access_sequence extends uvm_sequence #(ahb_transaction);
    `uvm_object_utils(ahb_access_sequence)
    ahb_transaction item;
    function new(string name="ahb_access_sequence"); super.new(name); endfunction
    task body();
        if (item == null) `uvm_fatal("AHB_SEQ", "Missing access item")
        start_item(item); finish_item(item);
    endtask
endclass
