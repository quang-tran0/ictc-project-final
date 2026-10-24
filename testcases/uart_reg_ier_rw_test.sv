// VPlan 1.06: IER RW fields
class uart_reg_ier_rw_test extends uart_base_test;
    `uvm_component_utils(uart_reg_ier_rw_test)

    function new(string name = "uart_reg_ier_rw_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        bus_write('h010, 32'h00000000);
        read_expect('h010, 32'h00000000, 32'h0000001f);
        bus_write('h010, 32'h00000001);
        read_expect('h010, 32'h00000001, 32'h0000001f);
        bus_write('h010, 32'h00000002);
        read_expect('h010, 32'h00000002, 32'h0000001f);
        bus_write('h010, 32'h00000004);
        read_expect('h010, 32'h00000004, 32'h0000001f);
        bus_write('h010, 32'h00000008);
        read_expect('h010, 32'h00000008, 32'h0000001f);
        bus_write('h010, 32'h00000010);
        read_expect('h010, 32'h00000010, 32'h0000001f);
        bus_write('h010, 32'h0000001f);
        read_expect('h010, 32'h0000001f, 32'h0000001f);
        bus_write('h010, 32'h00000000);
        read_expect('h010, 32'h00000000, 32'h0000001f);

        random_register_writes('h010, 'h1f);
    endtask
endclass
