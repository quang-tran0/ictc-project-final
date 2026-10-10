class uart_ahb_transfer_test extends uart_base_test;
    `uvm_component_utils(uart_ahb_transfer_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        logic [31:0] data;
        repeat(100) begin
            bit [7:0] value;
            value=$urandom;
            access(1,4,value,data,0); access(0,4,0,data,1);
            check_value(data===value,"AHB_SINGLE_INCR","Data mismatch across SINGLE/INCR");
            access(1,8,~value & 'hff,data,1); access(0,8,0,data,0);
            check_value(data===(~value & 'hff),"AHB_INCR_SINGLE","Data mismatch across INCR/SINGLE");
        end
        check_value(env.ahb.monitor.completed_count==400,"AHB_COUNT","Lost or duplicate bus transfers");
    endtask
endclass
