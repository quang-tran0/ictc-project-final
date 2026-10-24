class uart_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(uart_scoreboard)
    uvm_analysis_imp_ahb #(ahb_transaction, uart_scoreboard) ahb_imp;
    uvm_analysis_imp_uart #(uart_transaction, uart_scoreboard) uart_imp;
    uvm_analysis_imp_stimulus #(uart_transaction, uart_scoreboard) stimulus_imp;
    virtual uart_irq_if vif;
    uart_configuration cfg;
    logic [31:0] mdr = 0, dll = 0, dlh = 0, lcr = 3, ier = 0;
    uart_transaction tx_expected[$], input_expected[$];
    bit [7:0] rx_expected[$];
    bit tx_admission[$];
    bit check_rx_data = 1;
    int unsigned tx_compares, rx_compares, input_compares, reg_compares, bus_count;
    int unsigned rejected_tx, aborted_tx, aborted_rx;
    int tx_level = 0, rx_level = 0;
    int unsigned tx_nonempty_cycles;
    bit in_reset = 0;
    covergroup fifo_cg with function sample(int tx_count, int rx_count, bit push, bit pop);
        option.per_instance = 1;
        cp_tx: coverpoint tx_count {
            bins empty = {0};
            bins one = {1};
            bins partial = {[2:14]};
            bins almost_full = {15};
            bins full = {16};
        }
        cp_rx: coverpoint rx_count {
            bins empty = {0};
            bins one = {1};
            bins partial = {[2:14]};
            bins almost_full = {15};
            bins full = {16};
        }
        cp_push: coverpoint push;
        cp_pop: coverpoint pop;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ahb_imp = new("ahb_imp", this);
        uart_imp = new("uart_imp", this);
        stimulus_imp = new("stimulus_imp", this);
        fifo_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_irq_if)::get(this, "", "uart_irq_vif", vif) || vif == null)
            `uvm_fatal("SB_VIF", "Missing FIFO observation interface")
        if (!uvm_config_db#(uart_configuration)::get(this, "", "uart_cfg", cfg) || cfg == null)
            `uvm_fatal("SB_CFG", "Missing UART configuration")
    endfunction

    function void reset_model();
        aborted_tx += tx_expected.size();
        aborted_rx += rx_expected.size();
        tx_expected.delete();
        rx_expected.delete();
        input_expected.delete();
        tx_admission.delete();
        mdr = 0;
        dll = 0;
        dlh = 0;
        lcr = 3;
        ier = 0;
        tx_level = 0;
        rx_level = 0;
    endfunction

    function void equal32(logic [31:0] actual, logic [31:0] expected, bit [31:0] mask, string what);
        reg_compares++;
        if ((actual & mask) !== (expected & mask))
            `uvm_error("SB_REGISTER", $sformatf("%s actual=%08h expected=%08h mask=%08h", what, actual, expected, mask))
    endfunction

    function void write_ahb(ahb_transaction t);
        bit admitted;
        uart_transaction e;
        if (!t.completed)
            `uvm_error("SB_AHB", "Monitor published an incomplete transaction")
        bus_count++;
        if (t.addr >= 10'h020) begin
            if (t.hresp !== 1)
                `uvm_error("SB_RESERVED", "Reserved access did not return ERROR")
            if (t.xact_type == ahb_transaction::READ)
                equal32(t.rdata, 32'hffffffff, '1, "Reserved read");
            return;
        end
        if (t.hresp !== 0)
            `uvm_error("SB_AHB", "Mapped word access did not return OKAY")
        if (t.xact_type == ahb_transaction::WRITE) begin
            case (t.addr)
                'h000:mdr = t.data & 1;
                'h004:dll = t.data & 'hff;
                'h008:dlh = t.data & 'hff;
                'h00c:lcr = t.data & 'h3f;
                'h010:ier = t.data & 'h1f;
                'h018: begin
                    if (tx_admission.size() == 0) begin
                        `uvm_error("SB_TX_ACCEPT", "AHB TBR write lacks corresponding decoder access")
                        admitted = 0;
                    end else admitted = tx_admission.pop_front();
                    if (admitted) begin
                        e = uart_transaction::type_id::create("expected_tx");
                        e.data = t.data & (8'hff >> (8 - (5 + lcr[1:0])));
                        e.data_width = 5 + lcr[1:0];
                        e.stop_bits = 1 + lcr[2];
                        e.parity_mode = !lcr[3] ? int'(UART_PARITY_NONE) :
                        lcr[4] ? int'(UART_PARITY_EVEN) : int'(UART_PARITY_ODD);
                        e.period = real'((dlh << 8)|dll) * (mdr[0]?13:16) * 10ns;
                        tx_expected.push_back(e);
                    end else rejected_tx++;
                end
                default: begin
                end
            endcase
        end else begin
            case (t.addr)
                'h000:equal32(t.rdata, mdr, 1, "MDR");
                'h004:equal32(t.rdata, dll, 'hff, "DLL");
                'h008:equal32(t.rdata, dlh, 'hff, "DLH");
                'h00c:equal32(t.rdata, lcr, 'h3f, "LCR");
                'h010:equal32(t.rdata, ier, 'h1f, "IER");
                'h018:equal32(t.rdata, 0, 'hff, "TBR fixed zero");
                'h01c: begin
                    // Empty reads are intentionally undefined. A valid queued
                    // stimulus is compared under active WLS bits only.
                    if (check_rx_data && rx_expected.size() != 0) begin
                        bit [7:0] b;
                        b = rx_expected.pop_front();
                        rx_compares++;
                        if ((t.rdata & (8'hff >> (8 - cfg.data_width))) !== 32'(b))
                            `uvm_error("SB_RX_DATA", $sformatf("RBR=%02h expected=%02h", t.rdata, b))
                    end
                end
                default: begin
                end
            endcase
        end
    endfunction

    function void write_stimulus(uart_transaction t);
        uart_transaction e;
        $cast(e, t.clone());
        input_expected.push_back(e);
        if (check_rx_data && !t.inject_parity_error && !t.inject_stop_error)
            rx_expected.push_back(t.data);
    endfunction

    function void write_uart(uart_transaction t);
        uart_transaction e;
        if (t.direction == UART_TX) begin
            if (input_expected.size() == 0)
                `uvm_error("SB_RX_STIMULUS", "Unrequested input frame")
            else begin
                e = input_expected.pop_front();
                input_compares++;
                if (t.data !== e.data || t.inject_parity_error != e.inject_parity_error ||
                    t.inject_stop_error != e.inject_stop_error)
                    `uvm_error("SB_RX_STIMULUS", "Driven serial input differs from requested data/error")
            end
        end else begin
            if (tx_expected.size() == 0)
                `uvm_error("SB_UNEXPECTED_TX", $sformatf("Unexpected TX byte%02h", t.data))
            else begin
                e = tx_expected.pop_front();
                tx_compares++;
                if (t.data !== e.data || t.data_width != e.data_width ||
                    t.stop_bits != e.stop_bits || t.parity_mode != e.parity_mode)
                    `uvm_error("SB_TX_DATA",
                        $sformatf("TX=%02h expected=%02h width=%0d/%0d",
                            t.data, e.data, t.data_width, e.data_width))
                if (t.period != e.period)
                    `uvm_error("SB_TX_PERIOD",
                        $sformatf("TX checker period%0f does not match programmed%0f",
                            t.period, e.period))
            end
        end
    endfunction

    task run_phase(uvm_phase phase);
        bit [3:0] expected_flags, previous_bad = 'x;
        forever begin
            @(posedge vif.clk);
            if (vif.reset_n !== 1) begin
                if (!in_reset) reset_model();
                in_reset = 1;
            end else begin
                in_reset = 0;
                if (vif.apb_access && vif.apb_write && vif.apb_addr == 'h018)
                    tx_admission.push_back(tx_level < 16);
                // Own occupancy counters predict isolated full/empty handling;
                // no acceptance decision is taken from the DUT's full flag.
                case ({(vif.tx_wr && tx_level < 16), (vif.tx_rd && tx_level > 0)})
                    2'b10:tx_level++;
                    2'b01:tx_level--;
                    default: begin
                    end
                endcase
                case ({(vif.rx_wr && rx_level < 16), (vif.rx_rd && rx_level > 0)})
                    2'b10:rx_level++;
                    2'b01:rx_level--;
                    default: begin
                    end
                endcase
                if (tx_level > 0) tx_nonempty_cycles++;
                if (vif.tx_wr || vif.rx_wr || vif.tx_rd || vif.rx_rd)
                    fifo_cg.sample(tx_level, rx_level, vif.tx_wr || vif.rx_wr, vif.tx_rd || vif.rx_rd);
            end
            @(negedge vif.clk);
            if (vif.reset_n === 1) begin
                expected_flags = {rx_level == 0, rx_level == 16, tx_level == 0, tx_level == 16};
                if (vif.status[3:0] !== expected_flags) begin
                    if (vif.status[3:0] !== previous_bad)
                        `uvm_error("SB_FIFO",
                            $sformatf("FSR[3:0]=%h expected=%h TXlevel=%0d RXlevel=%0d",
                                vif.status[3:0], expected_flags, tx_level, rx_level))
                    previous_bad = vif.status[3:0];
                end else previous_bad = 'x;
            end
        end
    endtask

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (tx_expected.size() != 0)
            `uvm_error("SB_MISSING_TX", $sformatf("%0d TX frames missing", tx_expected.size()))
        if (rx_expected.size() != 0)
            `uvm_error("SB_MISSING_RX", $sformatf("%0d RX reads missing", rx_expected.size()))
        if (input_expected.size() != 0)
            `uvm_error("SB_MISSING_INPUT", "Input stimulus did not finish")
        if (tx_admission.size() != 0)
            `uvm_error("SB_AHB_MISSING", "TBR decoder access did not complete on AHB")
        if (check_rx_data && rx_level != 0)
            `uvm_error("SB_UNEXPECTED_RX", "Unread RX data remains at end of normal RX test")
        if (bus_count == 0)
            `uvm_error("SB_NO_TRAFFIC", "No observed AHB transactions")
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB_COUNTS",
            $sformatf("AHB=%0d reg=%0d TX=%0d RX=%0d input=%0d full-write-reject=%0d reset-abort=%0d/%0d",
                bus_count, reg_compares, tx_compares, rx_compares, input_compares, rejected_tx, aborted_tx, aborted_rx), UVM_LOW)
    endfunction
endclass
