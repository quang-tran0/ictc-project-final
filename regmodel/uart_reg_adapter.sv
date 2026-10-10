`ifndef UART_REG_ADAPTER__SV
`define UART_REG_ADAPTER__SV

class uart_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(uart_reg_adapter)

    function new(string name = "uart_reg_adapter");
        super.new(name);
        supports_byte_enable = 0;
        // AHB get/put contract returns a distinct completed response.
        provides_responses = 1;
    endfunction

    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        ahb_transaction bus;

        if ((rw.kind != UVM_READ && rw.kind != UVM_WRITE) ||
            rw.n_bits != 32 || rw.addr[1:0] != 0 ||
            rw.addr > uvm_reg_addr_t'(10'h3fc)) begin
            `uvm_error("UART_RAL_AHB_REQUEST",
                       "Expected a word-aligned 32-bit READ/WRITE within the 10-bit DUT address space")
            return null;
        end
        bus = ahb_transaction::type_id::create("bus");
        bus.addr = rw.addr[9:0];
        bus.data = rw.data[31:0];
        bus.xact_type = (rw.kind == UVM_WRITE) ? ahb_transaction::WRITE
                                               : ahb_transaction::READ;
        bus.burst_type = ahb_transaction::AHB_SINGLE;
        bus.xfer_size = ahb_transaction::SIZE_32BIT;
        return bus;
    endfunction

    virtual function void bus2reg(uvm_sequence_item bus_item,
                                 ref uvm_reg_bus_op rw);
        ahb_transaction bus;

        // Initialize outputs even on a bad cast; never retain a previous OK.
        rw.kind = UVM_READ;
        rw.addr = 0;
        rw.data = 0;
        rw.n_bits = 32;
        rw.byte_en = '1;
        rw.status = UVM_NOT_OK;
        if (!$cast(bus, bus_item) || bus == null) begin
            `uvm_error("UART_RAL_AHB_TYPE", "Expected a non-null ahb_transaction")
            return;
        end
        rw.kind = (bus.xact_type == ahb_transaction::WRITE) ? UVM_WRITE : UVM_READ;
        rw.addr = bus.addr;
        if (rw.kind == UVM_WRITE)
            rw.data = bus.data;

        if (bus.completed) begin
            if (rw.kind == UVM_READ) rw.data = bus.rdata;
            if (bus.hresp === 1'b0) rw.status = UVM_IS_OK;
        end
    endfunction
endclass

`endif
