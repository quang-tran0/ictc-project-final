`ifndef UART_LCR_REG__SV
`define UART_LCR_REG__SV

// Line control: baud enable, even parity select, parity enable, stop bits,
// and word length (WLS 0/1/2/3 selects 5/6/7/8 data bits).
class uart_lcr_reg extends uvm_reg;
    `uvm_object_utils(uart_lcr_reg)

    rand uvm_reg_field BGE;
    rand uvm_reg_field EPS;
    rand uvm_reg_field PEN;
    rand uvm_reg_field STB;
    rand uvm_reg_field WLS;

    function new(string name = "uart_lcr_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // Word-only bus: no field is individually accessible.
        BGE = uvm_reg_field::type_id::create("BGE",, get_full_name());
        BGE.configure(.parent(this), .size(1), .lsb_pos(5),
            .access("RW"), .volatile(0), .reset(1'h0),
            .has_reset(1), .is_rand(1), .individually_accessible(0));
        EPS = uvm_reg_field::type_id::create("EPS",, get_full_name());
        EPS.configure(.parent(this), .size(1), .lsb_pos(4),
            .access("RW"), .volatile(0), .reset(1'h0),
            .has_reset(1), .is_rand(1), .individually_accessible(0));
        PEN = uvm_reg_field::type_id::create("PEN",, get_full_name());
        PEN.configure(.parent(this), .size(1), .lsb_pos(3),
            .access("RW"), .volatile(0), .reset(1'h0),
            .has_reset(1), .is_rand(1), .individually_accessible(0));
        STB = uvm_reg_field::type_id::create("STB",, get_full_name());
        STB.configure(.parent(this), .size(1), .lsb_pos(2),
            .access("RW"), .volatile(0), .reset(1'h0),
            .has_reset(1), .is_rand(1), .individually_accessible(0));
        WLS = uvm_reg_field::type_id::create("WLS",, get_full_name());
        WLS.configure(.parent(this), .size(2), .lsb_pos(0),
            .access("RW"), .volatile(0), .reset(2'h3),
            .has_reset(1), .is_rand(1), .individually_accessible(0));
    endfunction

    // Reserved bits have no specified read value; compare meaningful bits only.
    virtual function bit do_check(uvm_reg_data_t expected,
        uvm_reg_data_t actual, uvm_reg_map map);
        return super.do_check(expected & 32'h0000003f,
                              actual & 32'h0000003f, map);
    endfunction
endclass

`endif
