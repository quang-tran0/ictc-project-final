// VPlan 6.08: RX read from empty
class uart_fifo_rx_empty_read_test extends uart_base_test;
    `uvm_component_utils(uart_fifo_rx_empty_read_test)

    function new(string name = "uart_fifo_rx_empty_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        logic [31:0] undefined_data;
        read_expect('h014, 8, 'h0c, "RX empty before read");
        bus_read('h01c, undefined_data);
        read_expect('h014, 8, 'h0c, "RX remains empty; returned data intentionally unchecked");
    endtask
endclass
