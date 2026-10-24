// VPlan 14.01: TX FIFO wraparound, 80-byte stream / 8N1 OSM16
class uart_fifo_tx_wraparound_test extends uart_base_test;
    `uvm_component_utils(uart_fifo_tx_wraparound_test)

    function new(string name = "uart_fifo_tx_wraparound_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        uart_ahb_sequence s;
        minimum_tx = 80;
        configure_uart();
        for (int i = 0; i < 80; i++) begin
            wait_status(1, 0);
            s = uart_ahb_sequence::type_id::create("random_wrap_write");
            s.add_random_write('h018, 'hff);
            s.start(env.ahb.sequencer);
        end
        wait_tx(80);
        read_expect('h014, 2, 3, "TX empty after more than4 pointer laps");
    endtask
endclass
