// VPlan 1.05: LCR RW fields
class uart_reg_lcr_rw_test extends uart_base_test;
    `uvm_component_utils(uart_reg_lcr_rw_test)

    function new(string name = "uart_reg_lcr_rw_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        bus_write('h004, 54);
        bus_write('h00c, 32'h00000000);
        read_expect('h00c, 32'h00000000, 32'h0000003f);
        bus_write('h00c, 32'h00000001);
        read_expect('h00c, 32'h00000001, 32'h0000003f);
        bus_write('h00c, 32'h00000002);
        read_expect('h00c, 32'h00000002, 32'h0000003f);
        bus_write('h00c, 32'h00000003);
        read_expect('h00c, 32'h00000003, 32'h0000003f);
        bus_write('h00c, 32'h0000003f);
        read_expect('h00c, 32'h0000003f, 32'h0000003f);
        bus_write('h00c, 32'h00000023);
        read_expect('h00c, 32'h00000023, 32'h0000003f);

        random_register_writes('h00c, 'h1f);
    endtask
endclass
