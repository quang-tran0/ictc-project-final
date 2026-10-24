// VPlan 4.13: TX 6N1 / 16×
class uart_tx_w6_none_s1_osm16_test extends uart_base_test;
    `uvm_component_utils(uart_tx_w6_none_s1_osm16_test)

    function new(string name = "uart_tx_w6_none_s1_osm16_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 1;
        configure_uart(6, UART_PARITY_NONE, 1, 16, 54);
        transmit('{8'h15});
        wait_tx(1);

        random_serial_frames(0);
    endtask
endclass
