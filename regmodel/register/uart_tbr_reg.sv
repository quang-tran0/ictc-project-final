`ifndef UART_TBR_REG__SV
`define UART_TBR_REG__SV

// TX FIFO write port, not ordinary storage. The specification defines a
// zero reset and zero low-byte readback; UVM WO does not model that readback.
// Verify fixed-zero reads and transmission side effects with future bus tests.
class uart_tbr_reg extends uvm_reg;
    `uvm_object_utils(uart_tbr_reg)

    rand uvm_reg_field tx_data;

    function new(string name = "uart_tbr_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // Word-only bus: no field is individually accessible.
        tx_data = uvm_reg_field::type_id::create("tx_data",, get_full_name());
        tx_data.configure(.parent(this), .size(8), .lsb_pos(0),
            .access("WO"), .volatile(0), .reset(8'h0),
            .has_reset(1), .is_rand(1), .individually_accessible(0));
        tx_data.set_compare(UVM_NO_CHECK);
        uvm_resource_db#(bit)::set({"REG::", get_full_name()},
                                  "NO_REG_TESTS", 1, this);
    endfunction

    // Reserved bits have no specified read value; compare meaningful bits only.
    virtual function bit do_check(uvm_reg_data_t expected,
        uvm_reg_data_t actual, uvm_reg_map map);
        return super.do_check(expected & 32'h000000ff,
                              actual & 32'h000000ff, map);
    endfunction
endclass

`endif
