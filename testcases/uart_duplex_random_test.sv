class uart_duplex_random_test extends uart_base_test;
    `uvm_component_utils(uart_duplex_random_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        int count=0;
        repeat(24) begin
            if(!uart_cfg.randomize() with {divisor inside {[2:16]};})
                `uvm_fatal("UART_RANDOMIZE","Cannot randomize a legal UART frame format")
            configure_uart(uart_cfg.data_width,uart_cfg.parity,uart_cfg.num_of_stop_bits,
                           uart_cfg.osm_sel,uart_cfg.divisor);
            fork
                begin repeat(8) write_reg('h18,$urandom); end
                begin repeat(8) send_rx($urandom); end
            join
            count+=8; read_rx(8); wait_tx(count);
            check_reg('h14,'ha,'hf);
        end
        require_counts(192,192);
    endtask
endclass
