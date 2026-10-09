class uart_base_test extends uvm_test;
    `uvm_component_utils(uart_base_test)

    function new(string name="uart_base_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction
endclass