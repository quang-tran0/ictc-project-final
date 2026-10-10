`ifndef UART_FSR_REG__SV
`define UART_FSR_REG__SV

// Hardware-updated FIFO/parity status. W1C: writing 1 clears, 0 preserves.
// Volatility does not itself update the mirror; future monitoring is required.
class uart_fsr_reg extends uvm_reg;
    `uvm_object_utils(uart_fsr_reg)

    uvm_reg_field parrity_error_status;
    uvm_reg_field rx_empty_status;
    uvm_reg_field rx_full_status;
    uvm_reg_field tx_empty_status;
    uvm_reg_field tx_full_status;

    function new(string name = "uart_fsr_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // Word-only bus: no field is individually accessible.
        parrity_error_status = uvm_reg_field::type_id::create("parrity_error_status",, get_full_name());
        parrity_error_status.configure(.parent(this), .size(1), .lsb_pos(4),
            .access("W1C"), .volatile(1), .reset(1'h0),
            .has_reset(1), .is_rand(0), .individually_accessible(0));
        parrity_error_status.set_compare(UVM_NO_CHECK);
        rx_empty_status = uvm_reg_field::type_id::create("rx_empty_status",, get_full_name());
        rx_empty_status.configure(.parent(this), .size(1), .lsb_pos(3),
            .access("RO"), .volatile(1), .reset(1'h1),
            .has_reset(1), .is_rand(0), .individually_accessible(0));
        rx_empty_status.set_compare(UVM_NO_CHECK);
        rx_full_status = uvm_reg_field::type_id::create("rx_full_status",, get_full_name());
        rx_full_status.configure(.parent(this), .size(1), .lsb_pos(2),
            .access("RO"), .volatile(1), .reset(1'h0),
            .has_reset(1), .is_rand(0), .individually_accessible(0));
        rx_full_status.set_compare(UVM_NO_CHECK);
        tx_empty_status = uvm_reg_field::type_id::create("tx_empty_status",, get_full_name());
        tx_empty_status.configure(.parent(this), .size(1), .lsb_pos(1),
            .access("RO"), .volatile(1), .reset(1'h1),
            .has_reset(1), .is_rand(0), .individually_accessible(0));
        tx_empty_status.set_compare(UVM_NO_CHECK);
        tx_full_status = uvm_reg_field::type_id::create("tx_full_status",, get_full_name());
        tx_full_status.configure(.parent(this), .size(1), .lsb_pos(0),
            .access("RO"), .volatile(1), .reset(1'h0),
            .has_reset(1), .is_rand(0), .individually_accessible(0));
        tx_full_status.set_compare(UVM_NO_CHECK);
    endfunction

    // Reserved bits have no specified read value; compare meaningful bits only.
    virtual function bit do_check(uvm_reg_data_t expected,
        uvm_reg_data_t actual, uvm_reg_map map);
        return super.do_check(expected & 32'h0000001f,
                              actual & 32'h0000001f, map);
    endfunction
endclass

`endif
