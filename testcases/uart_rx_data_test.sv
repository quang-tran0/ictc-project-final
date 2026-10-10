class uart_rx_data_test extends uart_base_test;
    `uvm_component_utils(uart_rx_data_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart();
        for(int value=0; value<256; value++) begin
            send_rx(value); read_rx(1);
        end
        require_counts(0,256);
    endtask
endclass
