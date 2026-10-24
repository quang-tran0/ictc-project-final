// VPlan 15.03: Two empty-FIFO IRQ sources with partial masking
class uart_irq_multisource_or_test extends uart_base_test;
    `uvm_component_utils(uart_irq_multisource_or_test)

    function new(string name = "uart_irq_multisource_or_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        read_expect('h014, 'h0a, 'h1f, "Two stable empty sources");
        bus_write('h010, 'h0a);
        check_irq(1);
        bus_write('h010, 'h08);
        check_irq(1);
        bus_write('h010, 0);
        check_irq(0);
        read_expect('h014, 'h0a, 'h1f, "Masking does not clear sources");
    endtask
endclass
