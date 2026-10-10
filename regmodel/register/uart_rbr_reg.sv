`ifndef UART_RBR_REG__SV
`define UART_RBR_REG__SV

// RX FIFO read port. Reads may pop data; an empty FIFO yields undefined data.
// has_reset=0 is intentional: the configure() reset argument is ignored.
// UVM's two-state mirror cannot represent the specification's unknown reset.
class uart_rbr_reg extends uvm_reg;
    `uvm_object_utils(uart_rbr_reg)

    uvm_reg_field rx_data;

    function new(string name = "uart_rbr_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // Word-only bus: no field is individually accessible.
        rx_data = uvm_reg_field::type_id::create("rx_data",, get_full_name());
        rx_data.configure(.parent(this), .size(8), .lsb_pos(0),
            .access("RO"), .volatile(1), .reset(8'h0),
            .has_reset(0), .is_rand(0), .individually_accessible(0));
        rx_data.set_compare(UVM_NO_CHECK);
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
