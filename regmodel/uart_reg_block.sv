`ifndef UART_REG_BLOCK__SV
`define UART_REG_BLOCK__SV

class uart_reg_block extends uvm_reg_block;
    `uvm_object_utils(uart_reg_block)

    rand uart_mdr_reg MDR;
    rand uart_dll_reg DLL;
    rand uart_dlh_reg DLH;
    rand uart_lcr_reg LCR;
    rand uart_ier_reg IER;
    uart_fsr_reg FSR;
    rand uart_tbr_reg TBR;
    uart_rbr_reg RBR;

    function new(string name = "uart_reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // 32-bit word transfers; byte offsets match the 10-bit DUT address port.
        // Subword accesses are unsupported, so no byte-lane ordering is assumed.
        default_map = create_map("default_map", 'h000, 4, UVM_LITTLE_ENDIAN, 1);

        MDR = uart_mdr_reg::type_id::create("MDR",, get_full_name());
        MDR.configure(this, null, "");
        MDR.build();
        default_map.add_reg(MDR, 'h000, "RW");

        DLL = uart_dll_reg::type_id::create("DLL",, get_full_name());
        DLL.configure(this, null, "");
        DLL.build();
        default_map.add_reg(DLL, 'h004, "RW");

        DLH = uart_dlh_reg::type_id::create("DLH",, get_full_name());
        DLH.configure(this, null, "");
        DLH.build();
        default_map.add_reg(DLH, 'h008, "RW");

        LCR = uart_lcr_reg::type_id::create("LCR",, get_full_name());
        LCR.configure(this, null, "");
        LCR.build();
        default_map.add_reg(LCR, 'h00c, "RW");

        IER = uart_ier_reg::type_id::create("IER",, get_full_name());
        IER.configure(this, null, "");
        IER.build();
        default_map.add_reg(IER, 'h010, "RW");

        FSR = uart_fsr_reg::type_id::create("FSR",, get_full_name());
        FSR.configure(this, null, "");
        FSR.build();
        default_map.add_reg(FSR, 'h014, "RW");

        TBR = uart_tbr_reg::type_id::create("TBR",, get_full_name());
        TBR.configure(this, null, "");
        TBR.build();
        default_map.add_reg(TBR, 'h018, "WO");

        RBR = uart_rbr_reg::type_id::create("RBR",, get_full_name());
        RBR.configure(this, null, "");
        RBR.build();
        default_map.add_reg(RBR, 'h01c, "RO");

        // No sequencer/adapter binding or automatic prediction at this stage.
        lock_model();
    endfunction
endclass

`endif
