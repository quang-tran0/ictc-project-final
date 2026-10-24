// VPlan 4.51: TX consecutive frame ordering
class uart_tx_stream_order_test extends uart_base_test;
    `uvm_component_utils(uart_tx_stream_order_test)

    function new(string name = "uart_tx_stream_order_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 4;
        configure_uart();
        transmit('{8'h12, 8'h34, 8'h56, 8'h78});
        wait_tx(4);
    endtask
endclass
