// VPlan 11.04: TBR reads preserve TX stream and return zero
class uart_tbr_read_no_push_test extends uart_base_test;
    `uvm_component_utils(uart_tbr_read_no_push_test)

    function new(string name = "uart_tbr_read_no_push_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        logic [31:0] d;
        minimum_tx = 3;
        configure_uart(8, UART_PARITY_NONE, 1, 16, 651);
        transmit('{8'h12, 8'h34, 8'h56});
        repeat (4) begin
            bus_read('h018, d);
            expect_value(d, 0, 'hff, "TBR reads zero while TX queued/active");
        end
        wait_tx(3);
        read_expect('h018, 0, 'hff, "TBR reads zero after drain");
    endtask
endclass
