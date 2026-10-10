`ifndef UART_REG_ADAPTER__SV
`define UART_REG_ADAPTER__SV

class uart_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(uart_reg_adapter)

    function new(string name = "uart_reg_adapter");
        super.new(name);
        supports_byte_enable = 0;
        // No separate response object is promised by the unfinished VIP.
        // Revisit this setting when its driver completion contract is defined.
        provides_responses = 0;
    endfunction

    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        ahb_transaction bus;

        if ((rw.kind != UVM_READ && rw.kind != UVM_WRITE) ||
            rw.n_bits != 32 || rw.addr[1:0] != 0 ||
            rw.addr > uvm_reg_addr_t'(32'hffff_ffff)) begin
            `uvm_error("UART_RAL_AHB_REQUEST",
                       "Expected a word-aligned 32-bit READ/WRITE with a 32-bit address")
            return null;
        end
        bus = ahb_transaction::type_id::create("bus");
        bus.addr = rw.addr[31:0];
        bus.data = rw.data[31:0];
        // 'type' is a keyword. The VIP declaration also needs to be escaped
        // (or renamed consistently) before the existing ahb_pkg can compile.
        bus.\type = (rw.kind == UVM_WRITE) ? ahb_transaction::WRITE
                                         : ahb_transaction::READ;
        bus.burst = ahb_transaction::AHB_SINGLE;
        bus.htrans = ahb_transaction::AHB_NONSEQ;
        // VIP has no HSIZE/HPROT/HSEL/HMASTLOCK fields. A future driver must
        // supply HSIZE=3'b010, unlocked selected transfer, and defined HPROT.
        // The IP ignores protection control and does not support locked access.
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
        rw.kind = (bus.\type == ahb_transaction::WRITE) ? UVM_WRITE : UVM_READ;
        rw.addr = bus.addr;
        if (rw.kind == UVM_WRITE)
            rw.data = bus.data;

        // No HRESP, completion marker, or defined captured-HRDATA contract
        // exists in ahb_transaction. In particular, data may be request data.
        // Once VIP exposes completed responses, map HRESP=0 to UVM_IS_OK and
        // HRESP=1 to UVM_NOT_OK, and copy actual HRDATA for completed reads.
        // Unknown/incomplete responses must remain UVM_NOT_OK.
        `uvm_error("UART_RAL_AHB_INCOMPLETE",
                   "AHB VIP lacks completion/HRESP/read-data semantics; RAL response rejected")
    endfunction
endclass

`endif
