`ifndef UART_MDR_REG__SV
`define UART_MDR_REG__SV

// Mode definition: OSM_SEL=0 selects 16x, OSM_SEL=1 selects 13x oversampling.
class uart_mdr_reg extends uvm_reg;
    `uvm_object_utils(uart_mdr_reg)

    rand uvm_reg_field OSM_SEL;

    function new(string name = "uart_mdr_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // Word-only bus: no field is individually accessible.
        OSM_SEL = uvm_reg_field::type_id::create("OSM_SEL",, get_full_name());
        OSM_SEL.configure(.parent(this), .size(1), .lsb_pos(0),
            .access("RW"), .volatile(0), .reset(1'h0),
            .has_reset(1), .is_rand(1), .individually_accessible(0));
    endfunction

    // Reserved bits have no specified read value; compare meaningful bits only.
    virtual function bit do_check(uvm_reg_data_t expected,
        uvm_reg_data_t actual, uvm_reg_map map);
        return super.do_check(expected & 32'h00000001,
                              actual & 32'h00000001, map);
    endfunction
endclass

`endif
