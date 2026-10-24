// VPlan 4.12: TX 5O2 / 13×
class uart_tx_w5_odd_s2_osm13_test extends uart_base_test;
    `uvm_component_utils(uart_tx_w5_odd_s2_osm13_test)

    function new(string name = "uart_tx_w5_odd_s2_osm13_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 2;
        configure_uart(5, UART_PARITY_ODD, 2, 13, 67);
        // A queued second frame makes the two-stop interval observable.
        transmit('{8'h15, 8'h15});
        wait_tx(2);

        random_serial_frames(0);
    endtask
endclass
