class uart_tx_data_test extends uart_base_test;
    `uvm_component_utils(uart_tx_data_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart();
        for(int value=0; value<256; value++) begin
            write_reg('h18,value); wait_tx(value+1);
        end
        require_counts(256,0);
    endtask
endclass
