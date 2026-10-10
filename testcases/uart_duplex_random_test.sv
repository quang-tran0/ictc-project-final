class uart_duplex_random_test extends uart_base_test;
    `uvm_component_utils(uart_duplex_random_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        int count=0;
        repeat(24) begin
            int width, parity, stops, divisor;
            bit osm;
            width=$urandom_range(5,8); parity=$urandom_range(0,2);
            stops=$urandom_range(1,2); osm=$urandom_range(0,1); divisor=$urandom_range(2,16);
            configure_uart(width,parity,stops,osm,divisor);
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
