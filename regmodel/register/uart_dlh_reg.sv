`ifndef UART_DLH_REG__SV
`define UART_DLH_REG__SV

// High eight bits of the 16-bit baud-rate divisor (DLH).
class uart_dlh_reg extends uvm_reg;
    `uvm_object_utils(uart_dlh_reg)

    rand uvm_reg_field DLH;

    function new(string name = "uart_dlh_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // Word-only bus: no field is individually accessible.
        DLH = uvm_reg_field::type_id::create("DLH",, get_full_name());
        DLH.configure(.parent(this), .size(8), .lsb_pos(0),
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
