class uart_rx_13x_div2_test extends uart_base_test;
    `uvm_component_utils(uart_rx_13x_div2_test)
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        configure_uart(5,0,1,1,2);
        `uvm_info("RX_BURST","Control: eight 0x17 frames, one extra idle bit between frames",UVM_LOW)
        #1ns; // Asynchronous stimulus, away from HCLK sampling edges.
        repeat(8) begin send_rx('h17); #(uart_cfg.bit_period()); end
        read_rx(8); require_counts(0,8);
        configure_uart(5,0,1,1,2);
        `uvm_info("RX_BURST","Reproduction: eight back-to-back 0x17 frames, no extra idle",UVM_LOW)
        #1ns;
        repeat(8) send_rx('h17);
        read_rx(8); require_counts(0,16);
    endtask
endclass
