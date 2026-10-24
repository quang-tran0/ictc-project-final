class uart_rx_sequence extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_rx_sequence)
    byte unsigned bytes_to_send[$];
    bit bad_parity = 0;
    bit bad_stop = 0;
    int unsigned bad_stop_index = 0;
    int unsigned gap_bits = 0;
    uart_configuration cfg;

    function new(string name = "uart_rx_sequence");
        super.new(name);
    endfunction

    task body();
        uart_transaction t;
        foreach (bytes_to_send[i]) begin
            t = uart_transaction::type_id::create("frame");
            t.direction = UART_TX;
            t.data = bytes_to_send[i];
            t.inject_parity_error = bad_parity;
            t.inject_stop_error = bad_stop;
            t.stop_error_index = bad_stop_index;
            start_item(t);
            finish_item(t);
            if (gap_bits != 0) #(cfg.bit_period() * gap_bits);
        end
    endtask
endclass
