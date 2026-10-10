class uart_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(uart_reg_adapter)
    function new(string name="uart_reg_adapter"); super.new(name); provides_responses=0; endfunction
    function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        ahb_transaction t=ahb_transaction::type_id::create("ral_access");
        t.addr=rw.addr[9:0]; t.data=rw.data;
        t.kind=(rw.kind==UVM_WRITE) ? ahb_transaction::WRITE : ahb_transaction::READ;
        return t;
    endfunction
    function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        ahb_transaction t;
        if (!$cast(t,bus_item)) `uvm_fatal("RAL_TYPE","Expected AHB transaction")
        rw.kind=(t.kind==ahb_transaction::WRITE) ? UVM_WRITE : UVM_READ;
        rw.addr=t.addr; rw.data=(rw.kind==UVM_READ) ? t.rdata : t.data;
        rw.status=(t.resp===0) ? UVM_IS_OK : UVM_NOT_OK;
    endfunction
endclass
