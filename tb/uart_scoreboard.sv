class uart_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(uart_scoreboard)
    uvm_analysis_imp_ahb #(ahb_transaction, uart_scoreboard) ahb_imp;
    uvm_analysis_imp_uart #(uart_transaction, uart_scoreboard) uart_imp;
    bit [31:0] regs[5];
    bit [7:0] tx_expected[$], rx_expected[$], rx_stimulus[$];
    bit rx_errors[$];
    int unsigned ahb_count, compared_count, tx_count, rx_count, rx_frame_count;
    int unsigned tx_dropped, reset_count;
    bit require_empty = 1;
    int unsigned expected_tx_rejections;
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ahb_imp = new("ahb_imp", this); uart_imp = new("uart_imp", this);
        reset_model();
    endfunction
    function void reset_model();
        regs = '{0, 0, 0, 3, 0};
        tx_expected.delete(); rx_expected.delete(); rx_stimulus.delete(); rx_errors.delete();
        expected_tx_rejections=0;
        reset_count++;
    endfunction
    function bit [31:0] mask(int index);
        case (index) 0:return 1; 1,2:return 'hff; 3:return 'h3f; 4:return 'h1f; default:return 0; endcase
    endfunction
    function void compare_word(string id, logic [31:0] got, bit [31:0] expected);
        compared_count++;
        if (got !== expected) `uvm_error(id, $sformatf("expected=%08h actual=%08h", expected, got))
    endfunction
    function void expect_rx(bit [7:0] value, bit bad_parity);
        rx_stimulus.push_back(value & ((1 << (5 + regs[3][1:0])) - 1));
        rx_errors.push_back(bad_parity && regs[3][3]);
    endfunction
    function void write_ahb(ahb_transaction t);
        int index;
        bit [7:0] expected;
        ahb_count++;
        if (t.resp !== (t.addr >= 'h20))
            `uvm_error("AHB_RESPONSE", $sformatf("addr=%03h expected HRESP=%0b got=%b", t.addr, t.addr >= 'h20, t.resp))
        if (t.addr >= 'h20) begin
            if (t.kind == ahb_transaction::READ) compare_word("RESERVED_DATA", t.rdata, '1);
            return;
        end
        index = t.addr / 4;
        if (t.kind == ahb_transaction::WRITE) begin
            if (index < 5) regs[index] = t.data & mask(index);
            if (t.addr == 'h18) begin
                if (expected_tx_rejections != 0) begin tx_dropped++; expected_tx_rejections--; end
                else tx_expected.push_back(t.data[7:0] & ((1 << (5 + regs[3][1:0])) - 1));
            end
        end else begin
            if (index < 5) compare_word("REGISTER_DATA", t.rdata, regs[index]);
            if (t.addr == 'h18) compare_word("TBR_READ_ZERO", t.rdata, 0);
            if (t.addr == 'h1c && rx_expected.size() != 0) begin
                expected = rx_expected.pop_front();
                compare_word("RX_DATA", t.rdata, {24'b0, expected});
                rx_count++;
            end
        end
    endfunction
    function void write_uart(uart_transaction t);
        bit [7:0] expected;
        bit bad_parity;
        if (t.direction == uart_transaction::UART_TX) begin
            tx_count++;
            if (tx_expected.size() == 0) `uvm_error("TX_UNEXPECTED", "Unrequested transmitted frame")
            else begin
                expected = tx_expected.pop_front();
                compare_word("TX_DATA", {24'b0,t.data}, {24'b0,expected});
            end
            if (t.parity_error) `uvm_error("TX_PARITY", $sformatf("data=%02h width=%0d mode=%0d", t.data,t.data_width,t.parity_mode))
            if (t.stop_error) `uvm_error("TX_STOP", "Transmitter stop bit is not high")
        end else begin
            rx_frame_count++;
            if (rx_stimulus.size() == 0) `uvm_error("RX_UNEXPECTED", "Unrequested RX stimulus")
            else begin
                expected = rx_stimulus.pop_front(); bad_parity = rx_errors.pop_front();
                compare_word("RX_STIMULUS", {24'b0,t.data}, {24'b0,expected});
                if (t.parity_error != bad_parity || t.stop_error)
                    `uvm_error("RX_STIMULUS_FORMAT", "RX driver did not generate requested frame")
                rx_expected.push_back(expected);
            end
        end
    endfunction
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (ahb_count == 0 || compared_count == 0) `uvm_error("NO_CHECKS", "Zero checked traffic")
        if(expected_tx_rejections) `uvm_error("UNUSED_REJECTIONS","Expected rejected writes were not issued")
        if (require_empty && (tx_expected.size() || rx_expected.size() || rx_stimulus.size()))
            `uvm_error("PENDING_DATA", $sformatf("TX=%0d RX=%0d stimulus=%0d", tx_expected.size(), rx_expected.size(), rx_stimulus.size()))
    endfunction
    function void report_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", $sformatf("AHB=%0d compared=%0d TX=%0d RX_frames=%0d RX_reads=%0d TX_ignored_full=%0d", ahb_count,compared_count,tx_count,rx_frame_count,rx_count,tx_dropped), UVM_NONE)
    endfunction
endclass
