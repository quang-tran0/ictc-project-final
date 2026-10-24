// VPlan 1.02: MDR RW fields
class uart_reg_mdr_rw_test extends uart_base_test;
    `uvm_component_utils(uart_reg_mdr_rw_test)

    function new(string name = "uart_reg_mdr_rw_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        bus_write('h000, 32'h00000000);
        read_expect('h000, 32'h00000000, 32'h00000001);
        bus_write('h000, 32'h00000001);
        read_expect('h000, 32'h00000001, 32'h00000001);
        bus_write('h000, 32'h00000000);
        read_expect('h000, 32'h00000000, 32'h00000001);

        random_register_writes('h000, 'h1);
    endtask
endclass
