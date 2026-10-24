// VPlan 4.31: TX 7E2 / 16×
class uart_tx_w7_even_s2_osm16_test extends uart_base_test;
    `uvm_component_utils(uart_tx_w7_even_s2_osm16_test)

    function new(string name = "uart_tx_w7_even_s2_osm16_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 2;
        configure_uart(7, UART_PARITY_EVEN, 2, 16, 54);
        // A queued second frame makes the two-stop interval observable.
        transmit('{8'h55, 8'h55});
        wait_tx(2);

        random_serial_frames(0);
    endtask
endclass
