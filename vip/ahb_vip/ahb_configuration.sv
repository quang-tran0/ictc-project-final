class ahb_configuration extends uvm_object;
    `uvm_object_utils(ahb_configuration)
    virtual ahb_if vif;
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    int unsigned timeout_cycles = 100;
    function new(string name="ahb_configuration"); super.new(name); endfunction
endclass
