class uart_rx_fifo_test extends uart_base_test;
    `uvm_component_utils(uart_rx_fifo_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart();
        repeat(3) begin
            for(int i=0; i<16; i++) begin
                send_rx(i*7);
                check_reg('h14,i==15 ? 4 : 0,'hc,"RX_FIFO_FLAGS");
            end
            read_rx(16); check_reg('h14,8,'hc);
        end
        require_counts(0,48);
    endtask
endclass
