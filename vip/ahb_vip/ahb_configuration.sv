class ahb_configuration extends uvm_object;
    `uvm_object_utils(ahb_configuration)

    virtual ahb_if vif;
    uvm_active_passive_enum is_active;

    function new(string name="ahb_configuration");
        super.new(name);
    endfunction
endclass