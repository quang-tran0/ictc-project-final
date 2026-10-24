// VPlan 1.07: FSR read-only FIFO status
class uart_reg_fsr_ro_test extends uart_base_test;
    `uvm_component_utils(uart_reg_fsr_ro_test)

    function new(string name = "uart_reg_fsr_ro_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        logic [31:0] before_status, after_status;
        minimum_tx = 3;
        configure_uart(8, UART_PARITY_NONE, 1, 16, 651);
        transmit('{8'h55, 8'h33, 8'h77});
        clocks(10);
        bus_read('h014, before_status);
        bus_write('h014, 'h0f);
        bus_read('h014, after_status);
        expect_value(after_status, before_status, 'h0f, "FSR RO bits ignore writes");
        wait_tx(3);
        read_expect('h014, 'h0a, 'h0f, "FIFO flags after drain");
    endtask
endclass
