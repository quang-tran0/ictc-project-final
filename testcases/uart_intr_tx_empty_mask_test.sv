// VPlan 7.04: TX FIFO empty interrupt masked
class uart_intr_tx_empty_mask_test extends uart_base_test;
    `uvm_component_utils(uart_intr_tx_empty_mask_test)

    function new(string name = "uart_intr_tx_empty_mask_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        read_expect('h014, 2, 2, "Active TX empty source");
        bus_write('h010, 0);
        check_irq(0);
    endtask
endclass
