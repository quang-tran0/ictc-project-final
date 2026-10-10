`ifndef UART_DLL_REG__SV
`define UART_DLL_REG__SV

// Low eight bits of the 16-bit baud-rate divisor (DLL).
class uart_dll_reg extends uvm_reg;
    `uvm_object_utils(uart_dll_reg)

    rand uvm_reg_field DLL;

    function new(string name = "uart_dll_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // Word-only bus: no field is individually accessible.
        DLL = uvm_reg_field::type_id::create("DLL",, get_full_name());
        DLL.configure(.parent(this), .size(8), .lsb_pos(0),
            .access("RW"), .volatile(0), .reset(8'h0),
            .has_reset(1), .is_rand(1), .individually_accessible(0));
    endfunction

    // Reserved bits have no specified read value; compare meaningful bits only.
    virtual function bit do_check(uvm_reg_data_t expected,
        uvm_reg_data_t actual, uvm_reg_map map);
        return super.do_check(expected & 32'h000000ff,
                              actual & 32'h000000ff, map);
    endfunction
endclass

`endif
