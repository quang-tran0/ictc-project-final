`ifndef UART_IER_REG__SV
`define UART_IER_REG__SV

// Interrupt enables. Preserve the specification's spelling of parrity.
class uart_ier_reg extends uvm_reg;
    `uvm_object_utils(uart_ier_reg)

    rand uvm_reg_field en_parrity_error;
    rand uvm_reg_field en_rx_fifo_empty;
    rand uvm_reg_field en_rx_fifo_full;
    rand uvm_reg_field en_tx_fifo_empty;
    rand uvm_reg_field en_tx_fifo_full;

    function new(string name = "uart_ier_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // Word-only bus: no field is individually accessible.
        en_parrity_error = uvm_reg_field::type_id::create("en_parrity_error",, get_full_name());
        en_parrity_error.configure(.parent(this), .size(1), .lsb_pos(4),
            .access("RW"), .volatile(0), .reset(1'h0),
            .has_reset(1), .is_rand(1), .individually_accessible(0));
        en_rx_fifo_empty = uvm_reg_field::type_id::create("en_rx_fifo_empty",, get_full_name());
        en_rx_fifo_empty.configure(.parent(this), .size(1), .lsb_pos(3),
            .access("RW"), .volatile(0), .reset(1'h0),
            .has_reset(1), .is_rand(1), .individually_accessible(0));
        en_rx_fifo_full = uvm_reg_field::type_id::create("en_rx_fifo_full",, get_full_name());
        en_rx_fifo_full.configure(.parent(this), .size(1), .lsb_pos(2),
            .access("RW"), .volatile(0), .reset(1'h0),
            .has_reset(1), .is_rand(1), .individually_accessible(0));
        en_tx_fifo_empty = uvm_reg_field::type_id::create("en_tx_fifo_empty",, get_full_name());
        en_tx_fifo_empty.configure(.parent(this), .size(1), .lsb_pos(1),
            .access("RW"), .volatile(0), .reset(1'h0),
            .has_reset(1), .is_rand(1), .individually_accessible(0));
        en_tx_fifo_full = uvm_reg_field::type_id::create("en_tx_fifo_full",, get_full_name());
        en_tx_fifo_full.configure(.parent(this), .size(1), .lsb_pos(0),
            .access("RW"), .volatile(0), .reset(1'h0),
            .has_reset(1), .is_rand(1), .individually_accessible(0));
    endfunction

    // Reserved bits have no specified read value; compare meaningful bits only.
    virtual function bit do_check(uvm_reg_data_t expected,
        uvm_reg_data_t actual, uvm_reg_map map);
        return super.do_check(expected & 32'h0000001f,
                              actual & 32'h0000001f, map);
    endfunction
endclass

`endif
