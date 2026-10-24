// VPlan 13.01: TX unused upper bits cannot change 5E1 frame
class uart_tx_upper_data_mask_test extends uart_base_test;
    `uvm_component_utils(uart_tx_upper_data_mask_test)

    function new(string name = "uart_tx_upper_data_mask_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 2;
        configure_uart(5, UART_PARITY_EVEN);
        bus_write('h018, 'h00000001);
        bus_write('h018, 'hffff00e1);
        wait_tx(2);
    endtask
endclass
