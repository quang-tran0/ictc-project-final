class uart_reg_block extends uvm_reg_block;
    `uvm_object_utils(uart_reg_block)
    uart_register regs[8];
    function new(string name="uart_reg_block"); super.new(name,UVM_NO_COVERAGE); endfunction
    function void build();
        string names[8]='{"MDR","DLL","DLH","LCR","IER","FSR","TBR","RBR"};
        default_map=create_map("ahb_map",0,4,UVM_LITTLE_ENDIAN,1);
        foreach(regs[i]) begin
            regs[i]=uart_register::type_id::create(names[i]);
            regs[i].configure(this); regs[i].build(i*4);
            default_map.add_reg(regs[i],i*4,i==6 ? "WO" : ((i==7) ? "RO" : "RW"));
        end
        lock_model(); reset();
    endfunction
endclass
