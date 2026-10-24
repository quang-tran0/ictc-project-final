// VPlan 14.02: RX FIFO wraparound with partial drains / 8N1 OSM16
class uart_fifo_rx_wraparound_test extends uart_base_test;
    `uvm_component_utils(uart_fifo_rx_wraparound_test)

    function new(string name = "uart_fifo_rx_wraparound_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_scenario();
        minimum_rx = 80;
        configure_uart();
        for (int batch = 0; batch < 10; batch++) begin
            uart_random_sequence s;
            s = uart_random_sequence::type_id::create("random_wrap_rx");
            s.cfg = uart_cfg;
            s.width = 8;
            s.serial_sequencer = env.uart.sequencer;
            if (!s.randomize() with { frame_count == 8; })
                `uvm_fatal("RAND_UART", "Cannot solve RX wraparound traffic")
            s.start(null);
            clocks(2);
            if (batch % 2 == 0) begin
                logic [31:0] d;
                repeat (5) bus_read('h01c, d);
                read_expect('h014, 0, 'h0c, "Partial drain leaves3 queued bytes");
            end else drain_rx(11);
        end
        read_expect('h014, 8, 'h0c, "RX empty after80 ordered reads");
    endtask
endclass
