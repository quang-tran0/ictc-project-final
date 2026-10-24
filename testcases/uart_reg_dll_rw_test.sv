// VPlan 1.03: DLL RW fields
class uart_reg_dll_rw_test extends uart_base_test;
    `uvm_component_utils(uart_reg_dll_rw_test)

    function new(string name = "uart_reg_dll_rw_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        bus_write('h004, 32'h00000000);
        read_expect('h004, 32'h00000000, 32'h000000ff);
        bus_write('h004, 32'h0000008b);
        read_expect('h004, 32'h0000008b, 32'h000000ff);
        bus_write('h004, 32'h000000ff);
        read_expect('h004, 32'h000000ff, 32'h000000ff);

        random_register_writes('h004, 'hff);
    endtask
endclass
