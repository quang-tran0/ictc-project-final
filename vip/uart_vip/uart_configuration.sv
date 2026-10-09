class uart_configuration extends uvm_object;
    `uvm_object_utils(uart_configuration)

    virtual uart_if vif;
    uvm_active_passive_enum is_active;

    function new(string name="uart_configuration");
        super.new(name);
    endfunction
endclass