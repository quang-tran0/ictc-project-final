// VPlan 10.02: Reset during TX data bit3, 8E1 / OSM16
class uart_reset_tx_phase_test extends uart_base_test;
    `uvm_component_utils(uart_reset_tx_phase_test)

    function new(string name = "uart_reset_tx_phase_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 1;
        configure_uart(8, UART_PARITY_EVEN);
        fork
            begin
                @(negedge uart_vif.rx);
                #(uart_cfg.bit_period() * 4.5);
                reset_dut();
            end
            begin
                bus_write('h018, 'ha6);
            end
        join
        check_reset_defaults();
        configure_uart(8, UART_PARITY_EVEN);
        transmit('{8'h5a});
        wait_tx(1);
        expect_value(env.scoreboard.aborted_tx, 1, '1, "Interrupted TX expectation flushed by reset");
    endtask
endclass
