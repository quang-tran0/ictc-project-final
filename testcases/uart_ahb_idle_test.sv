class uart_ahb_idle_test extends uart_base_test;
    `uvm_component_utils(uart_ahb_idle_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        logic [31:0] data;
        int before_count;
        write_reg(4,'h5a); before_count=env.ahb.monitor.completed_count;
        access(1,4,'hff,data,0,0,1);
        access(1,4,'haa,data,0,1,1);
        access(1,4,'hcc,data,0,2,0);
        cycles(10);
        check_value(env.ahb.monitor.completed_count==before_count,"AHB_IGNORED_COUNT","Inactive cycle accepted");
        check_reg(4,'h5a);
    endtask
endclass
