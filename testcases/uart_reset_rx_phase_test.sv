// VPlan 10.03: Reset during RX data bit3, 8E1 / OSM16
class uart_reset_rx_phase_test extends uart_base_test;
    `uvm_component_utils(uart_reset_rx_phase_test)

    function new(string name = "uart_reset_rx_phase_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_rx = 1;
        minimum_input = 1;
        configure_uart(8, UART_PARITY_EVEN);
        fork
            begin
                @(negedge uart_vif.tx);
                #(uart_cfg.bit_period() * 4.5);
                reset_dut();
            end
            begin
                send_rx('{8'ha6});
            end
        join
        check_reset_defaults();
        configure_uart(8, UART_PARITY_EVEN);
        send_rx('{8'h5a});
        drain_rx(1);
        expect_value(env.scoreboard.aborted_rx, 1, '1, "Interrupted RX expectation flushed by reset");
    endtask
endclass
