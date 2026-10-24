// VPlan 1.10: Reserved address read error
class uart_reg_reserved_read_test extends uart_base_test;
    `uvm_component_utils(uart_reg_reserved_read_test)

    function new(string name = "uart_reg_reserved_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        logic [31:0] d;
        for (int a = 'h020; a <= 'h3fc; a += 4) begin
            bus_read(10'(a), d, 0, 1);
            expect_value(d, '1, '1, "Reserved read data");
        end
    endtask
endclass
