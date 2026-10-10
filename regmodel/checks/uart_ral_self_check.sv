module uart_ral_self_check;
    import uvm_pkg::*;
`ifndef UART_RAL_MODEL_ONLY
    import ahb_pkg::*;
`endif
    import uart_register_pkg::*;
    import uart_regmodel_pkg::*;
    `include "uvm_macros.svh"
    `include "uart_ral_expected_error.sv"

    uart_reg_block model;
    int unsigned checks;
    int unsigned failures;

    function automatic void check(bit condition, string message);
        checks++;
        if (!condition) begin
            failures++;
            `uvm_error("UART_RAL_CHECK", message)
        end
    endfunction

    function automatic void check_register(uvm_reg rg, string name,
        uvm_reg_addr_t offset, string rights, int unsigned field_count,
        uvm_reg_data_t mask, uvm_reg_data_t reset_value, bit has_reset = 1);
        uvm_reg_field fields[$];
        uvm_reg_addr_t addresses[];
        int bytes;

        if (rg == null)
            `uvm_fatal("UART_RAL_CHECK", {"Missing register ", name})
        check(rg.get_name() == name, {name, ": name"});
        check(rg.get_parent() == model, {name, ": parent"});
        check(rg.get_n_bits() == 32, {name, ": width"});
        check(rg.get_offset(model.default_map) == offset, {name, ": offset"});
        check(rg.get_rights(model.default_map) == rights, {name, ": rights"});
        check(rg.is_in_map(model.default_map), {name, ": map membership"});
        // Lookup is not an access-permission check in UVM 1.2; use rights above.
        if (rights != "WO")
            check(model.default_map.get_reg_by_offset(offset, 1) == rg,
                  {name, ": read lookup"});
        if (rights != "RO")
            check(model.default_map.get_reg_by_offset(offset, 0) == rg,
                  {name, ": write lookup"});
        bytes = rg.get_addresses(model.default_map, addresses);
        check(bytes == 4 && addresses.size() == 1, {name, ": single word"});
        if (addresses.size() == 1)
            check(addresses[0] == offset, {name, ": physical byte address"});
        rg.get_fields(fields);
        check(fields.size() == field_count, {name, ": field count"});
        if (has_reset) begin
            check((rg.get_reset() & mask) == reset_value, {name, ": reset"});
            check((rg.get_mirrored_value() & mask) == reset_value,
                  {name, ": reset mirror"});
        end
        // No read value is specified for reserved bits. UVM data is two-state.
        check(rg.do_check(0, ~mask, model.default_map),
              {name, ": reserved ones must be ignored"});
    endfunction

    function automatic void check_field(uvm_reg rg, string name,
        int unsigned width, int unsigned lsb, string access,
        uvm_reg_data_t reset_value, bit has_reset = 1, bit is_volatile = 0,
        uvm_check_e compare_policy = UVM_CHECK);
        uvm_reg_field field;
        field = rg.get_field_by_name(name);
        if (field == null)
            `uvm_fatal("UART_RAL_CHECK", {"Missing field ", rg.get_name(), ".", name})
        check(field.get_n_bits() == width, {name, ": width"});
        check(field.get_lsb_pos() == lsb, {name, ": lsb"});
        check(field.get_access(model.default_map) == access, {name, ": access"});
        check(field.is_volatile() == is_volatile, {name, ": volatility"});
        check(field.get_compare() == compare_policy, {name, ": comparison"});
        check(field.has_reset() == has_reset, {name, ": reset presence"});
        if (has_reset) begin
            check(field.get_reset() == reset_value, {name, ": reset value"});
            check(field.get_mirrored_value() == reset_value, {name, ": mirror"});
        end
    endfunction

    initial begin
        uvm_reg registers[$];
        uvm_reg mapped_registers[$];
        uvm_reg_map maps[$];
`ifndef UART_RAL_MODEL_ONLY
        uart_reg_adapter adapter;
        ahb_transaction bus;
        uvm_sequence_item item;
        uvm_reg_bus_op op;
`endif
        uart_ral_expected_error catcher;
        uvm_report_server server;
        bit excluded;

        model = uart_reg_block::type_id::create("model");
        model.configure(null, "");
        model.build();
        model.reset("HARD");
        check(model.is_locked(), "Block must be locked by build()");
        if (model.default_map == null)
            `uvm_fatal("UART_RAL_CHECK", "Missing default map")
        model.get_registers(registers);
        model.get_maps(maps);
        model.default_map.get_registers(mapped_registers);
        check(registers.size() == 8, "Exactly eight registers");
        check(mapped_registers.size() == 8, "Exactly eight mapped registers");
        check(maps.size() == 1, "Exactly one map");
        check(model.default_map.get_base_addr() == 0, "Map base");
        check(model.default_map.get_n_bytes() == 4, "32-bit bus");
        check(model.default_map.get_addr_unit_bytes() == 1, "Byte addressed");
        check(model.default_map.get_endian() == UVM_LITTLE_ENDIAN, "Endianness");
        check(model.default_map.get_sequencer() == null, "No sequencer connected");
        check(model.default_map.get_adapter() == null, "No adapter connected");
        check(!model.default_map.get_auto_predict(), "Auto prediction disabled");

        check_register(model.MDR, "MDR", 'h000, "RW", 1, 'h01, 0);
        check_register(model.DLL, "DLL", 'h004, "RW", 1, 'hff, 0);
        check_register(model.DLH, "DLH", 'h008, "RW", 1, 'hff, 0);
        check_register(model.LCR, "LCR", 'h00c, "RW", 5, 'h3f, 3);
        check_register(model.IER, "IER", 'h010, "RW", 5, 'h1f, 0);
        check_register(model.FSR, "FSR", 'h014, "RW", 5, 'h1f, 'h0a);
        check_register(model.TBR, "TBR", 'h018, "WO", 1, 'hff, 0);
        check_register(model.RBR, "RBR", 'h01c, "RO", 1, 'hff, 0, 0);

        check_field(model.MDR, "OSM_SEL", 1, 0, "RW", 0);
        check_field(model.DLL, "DLL", 8, 0, "RW", 0);
        check_field(model.DLH, "DLH", 8, 0, "RW", 0);
        check_field(model.LCR, "BGE", 1, 5, "RW", 0);
        check_field(model.LCR, "EPS", 1, 4, "RW", 0);
        check_field(model.LCR, "PEN", 1, 3, "RW", 0);
        check_field(model.LCR, "STB", 1, 2, "RW", 0);
        check_field(model.LCR, "WLS", 2, 0, "RW", 3);
        check_field(model.IER, "en_parrity_error", 1, 4, "RW", 0);
        check_field(model.IER, "en_rx_fifo_empty", 1, 3, "RW", 0);
        check_field(model.IER, "en_rx_fifo_full", 1, 2, "RW", 0);
        check_field(model.IER, "en_tx_fifo_empty", 1, 1, "RW", 0);
        check_field(model.IER, "en_tx_fifo_full", 1, 0, "RW", 0);
        check_field(model.FSR, "parrity_error_status", 1, 4, "W1C", 0, 1, 1, UVM_NO_CHECK);
        check_field(model.FSR, "rx_empty_status", 1, 3, "RO", 1, 1, 1, UVM_NO_CHECK);
        check_field(model.FSR, "rx_full_status", 1, 2, "RO", 0, 1, 1, UVM_NO_CHECK);
        check_field(model.FSR, "tx_empty_status", 1, 1, "RO", 1, 1, 1, UVM_NO_CHECK);
        check_field(model.FSR, "tx_full_status", 1, 0, "RO", 0, 1, 1, UVM_NO_CHECK);
        check_field(model.TBR, "tx_data", 8, 0, "WO", 0, 1, 0, UVM_NO_CHECK);
        check_field(model.RBR, "rx_data", 8, 0, "RO", 0, 0, 1, UVM_NO_CHECK);

        for (int offset = 'h020; offset <= 'h3ff; offset++) begin
            check(model.default_map.get_reg_by_offset(offset, 1) == null,
                  $sformatf("Reserved read address 0x%03x is unmapped", offset));
            check(model.default_map.get_reg_by_offset(offset, 0) == null,
                  $sformatf("Reserved write address 0x%03x is unmapped", offset));
        end
        excluded = 0;
        check(uvm_resource_db#(bit)::read_by_name("REG::model.TBR", "NO_REG_TESTS", excluded)
              && excluded, "TBR excluded from automatic tests");
        excluded = 0;
        check(uvm_resource_db#(bit)::read_by_name("REG::model.RBR", "NO_REG_TESTS", excluded)
              && excluded, "RBR excluded from automatic tests");

        // Exercise UVM prediction only: no frontdoor, driver, DUT or FIFO model.
        check(model.FSR.parrity_error_status.predict(1), "Seed parity mirror");
        check(model.FSR.parrity_error_status.predict(0, -1, UVM_PREDICT_WRITE,
              UVM_FRONTDOOR, model.default_map), "Predict W1C zero");
        check(model.FSR.parrity_error_status.get_mirrored_value() == 1,
              "W1C zero leaves parity set");
        check(model.FSR.parrity_error_status.predict(1, -1, UVM_PREDICT_WRITE,
              UVM_FRONTDOOR, model.default_map), "Predict W1C one");
        check(model.FSR.parrity_error_status.get_mirrored_value() == 0,
              "W1C one clears parity");
        foreach (registers[i])
            check(registers[i].predict('1), "Perturb mirrors before reset");
        model.reset("HARD");
        foreach (registers[i]) begin
            uvm_reg_field fields[$];
            registers[i].get_fields(fields);
            foreach (fields[j]) begin
                if (fields[j].has_reset())
                    check(fields[j].get_mirrored_value() == fields[j].get_reset(),
                          {fields[j].get_full_name(), ": reinitialized mirror"});
            end
        end
        check(!model.RBR.rx_data.has_reset(), "RBR still has no HARD reset");
        check(model.RBR.rx_data.get_mirrored_value() == 'hff,
              "Reset does not overwrite the unreset RBR mirror");

        catcher = uart_ral_expected_error::type_id::create("catcher");
        catcher.expected_id = "RegModel";
        uvm_report_cb::add(null, catcher);
        check(!model.MDR.do_check(0, 1, model.default_map),
              "Meaningful RW bit mismatch must fail comparison");
        uvm_report_cb::delete(null, catcher);
        check(catcher.count == 1, "Meaningful mismatch reports an error");

`ifndef UART_RAL_MODEL_ONLY
        adapter = uart_reg_adapter::type_id::create("adapter");
        check(!adapter.supports_byte_enable, "No byte enables");
        check(!adapter.provides_responses, "No separate response contract claimed");
        foreach (registers[i]) begin
            for (int direction = 0; direction < 2; direction++) begin
                op.kind = direction ? UVM_WRITE : UVM_READ;
                op.addr = registers[i].get_offset(model.default_map);
                op.data = 'h89abcdef;
                op.n_bits = 32;
                op.byte_en = '1;
                item = adapter.reg2bus(op);
                if (!$cast(bus, item) || bus == null)
                    `uvm_fatal("UART_RAL_CHECK", "Adapter did not return ahb_transaction")
                check(bus.addr == op.addr, "Adapter address");
                check(bus.data == op.data[31:0], "Adapter 32-bit payload");
                check(bus.\type == (direction ? ahb_transaction::WRITE : ahb_transaction::READ),
                      "Adapter direction");
                check(bus.burst == ahb_transaction::AHB_SINGLE, "SINGLE transfer");
                check(bus.htrans == ahb_transaction::AHB_NONSEQ, "NONSEQ transfer");
            end
        end
        catcher.expected_id = "UART_RAL_AHB_INCOMPLETE";
        catcher.count = 0;
        uvm_report_cb::add(null, catcher);
        for (int direction = 0; direction < 2; direction++) begin
            bus.\type = direction ? ahb_transaction::WRITE : ahb_transaction::READ;
            op.status = UVM_IS_OK;
            adapter.bus2reg(bus, op);
            check(op.status == UVM_NOT_OK, "Incomplete VIP cannot report success");
            check(op.kind == (direction ? UVM_WRITE : UVM_READ), "Response direction");
            check(op.addr == bus.addr && op.n_bits == 32, "Response metadata");
            check(op.data == (direction ? uvm_reg_data_t'(bus.data) : 0),
                  "Never present request data as completed read data");
        end
        uvm_report_cb::delete(null, catcher);
        check(catcher.count == 2, "Both incomplete responses report errors");

        catcher.expected_id = "UART_RAL_AHB_TYPE";
        catcher.count = 0;
        uvm_report_cb::add(null, catcher);
        op.status = UVM_IS_OK;
        adapter.bus2reg(null, op);
        check(op.status == UVM_NOT_OK, "Null response is rejected");
        item = uvm_sequence_item::type_id::create("wrong_item");
        op.status = UVM_IS_OK;
        adapter.bus2reg(item, op);
        check(op.status == UVM_NOT_OK, "Wrong response type is rejected");
        uvm_report_cb::delete(null, catcher);
        check(catcher.count == 2, "Invalid response types report errors");

        catcher.expected_id = "UART_RAL_AHB_REQUEST";
        catcher.count = 0;
        uvm_report_cb::add(null, catcher);
        op.kind = UVM_WRITE;
        op.addr = 0;
        op.n_bits = 8;
        check(adapter.reg2bus(op) == null, "Subword requests are rejected");
        op.n_bits = 32;
        op.addr = 1;
        check(adapter.reg2bus(op) == null, "Unaligned requests are rejected");
        if ($bits(op.addr) > 32) begin
            op.addr = uvm_reg_addr_t'(1) << 32;
            check(adapter.reg2bus(op) == null, "Address truncation is rejected");
        end
        uvm_report_cb::delete(null, catcher);
        check(catcher.count == (($bits(op.addr) > 32) ? 3 : 2),
              "Invalid requests report errors");
`endif

        server = uvm_report_server::get_server();
        if (failures != 0 || server.get_severity_count(UVM_ERROR) != 0 ||
            server.get_severity_count(UVM_FATAL) != 0)
            `uvm_fatal("UART_RAL_CHECK", $sformatf("RAL check failed: %0d failures", failures))
        `uvm_info("UART_RAL_CHECK", $sformatf("RAL STRUCTURAL CHECK PASSED (%0d checks; no DUT accesses)", checks), UVM_NONE)
        $finish;
    end
endmodule
