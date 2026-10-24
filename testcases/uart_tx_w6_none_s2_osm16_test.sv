// VPlan 4.15: TX 6N2 / 16×
class uart_tx_w6_none_s2_osm16_test extends uart_base_test;
    `uvm_component_utils(uart_tx_w6_none_s2_osm16_test)

    function new(string name = "uart_tx_w6_none_s2_osm16_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 2;
        configure_uart(6, UART_PARITY_NONE, 2, 16, 54);
        // A queued second frame makes the two-stop interval observable.
        transmit('{8'h15, 8'h15});
        wait_tx(2);

        random_serial_frames(0);
    endtask
endclass
