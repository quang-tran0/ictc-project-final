class uart_reserved_access_test extends uart_base_test;
    `uvm_component_utils(uart_reserved_access_test)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    task scenario();
        logic [31:0] data;
        for(int addr='h20; addr<='h3fc; addr+=4) begin
            write_reg(addr,$urandom); read_reg(addr,data);
            check_value(data===32'hffffffff,"RESERVED_SWEEP",$sformatf("addr=%03h actual=%08h",addr,data));
            write_reg(4,addr & 'hff); check_reg(4,addr & 'hff);
        end
        check_value(env.ahb.monitor.error_count==496,"RESERVED_COUNT","Expected one ERROR per reserved read/write");
    endtask
endclass
