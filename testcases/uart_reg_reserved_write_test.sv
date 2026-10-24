// VPlan 1.11: Reserved address write error
class uart_reg_reserved_write_test extends uart_base_test;
    `uvm_component_utils(uart_reg_reserved_write_test)

    function new(string name = "uart_reg_reserved_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_tx = 2;
        minimum_rx = 1;
        configure_uart(8, UART_PARITY_NONE, 1, 16, 651);
        send_rx('{8'ha6});
        transmit('{8'h55, 8'h33});
        bus_write('h010, 'h08);
        for (int a = 'h020; a <= 'h3fc; a += 4) begin
            bus_write(10'(a), 32'h5a5a0000|a, 0, 1);
            read_expect('h000, 0, 1);
            read_expect('h004, 'h8b, 'hff);
            read_expect('h008, 2, 'hff);
            read_expect('h00c, 'h23, 'h3f);
            read_expect('h010, 8, 'h1f);
        end
        drain_rx(1);
        wait_tx(2);
    endtask
endclass
