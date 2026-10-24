class uart_irq_monitor extends uvm_monitor;
    `uvm_component_utils(uart_irq_monitor)
    virtual uart_irq_if vif;
    uvm_analysis_port #(logic) analysis_port;
    int unsigned checked_cycles, assertions;
    covergroup irq_cg with function sample(bit [4:0] status, bit [4:0] enables, bit irq);
        option.per_instance = 1;
        cp_status: coverpoint status {
            bins reset_empty = {5'h0a};
            bins tx_full = {5'h09};
            bins rx_full = {5'h06};
            bins other = default;
        }
        cp_enables: coverpoint enables {
            bins none = {0};
            bins individual[] = {1, 2, 4, 8, 16};
            bins two_empty = {10};
            bins other = default;
        }
        cp_irq: coverpoint irq;
        source_mask: cross cp_enables, cp_irq;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
        irq_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_irq_if)::get(this, "", "uart_irq_vif", vif) || vif == null)
            `uvm_fatal("UART_IRQ_VIF", "Missing IRQ interface")
    endfunction

    task run_phase(uvm_phase phase);
        logic expected, previous;
        int stable = 0;
        bit mismatch_reported = 0;
        logic [10:0] last_sample = 'x;
        forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.reset_n !== 1) begin
                stable = 0;
                previous = 1'bx;
                continue;
            end
            expected = |(vif.monitor_cb.status & vif.monitor_cb.enables);
            if (expected === previous) begin
                if (stable < 8) stable++;
            end else begin
                stable = 0;
                mismatch_reported = 0;
            end
            // Ignore transitions; compare only a stable source/mask window.
            if (stable >= 4) begin
                checked_cycles++;
                if (vif.monitor_cb.interrupt !== expected && !mismatch_reported) begin
                    mismatch_reported = 1;
                    `uvm_error("UART_IRQ",
                        $sformatf("IRQ=%b expected=%b status=%02h IER=%02h",
                            vif.monitor_cb.interrupt, expected, vif.monitor_cb.status, vif.monitor_cb.enables))
                end
                if (vif.monitor_cb.interrupt === expected) mismatch_reported = 0;
            end
            if (vif.monitor_cb.interrupt === 1 && previous === 0) assertions++;
            previous = expected;
            if ({vif.monitor_cb.status, vif.monitor_cb.enables, vif.monitor_cb.interrupt} !== last_sample) begin
                irq_cg.sample(vif.monitor_cb.status, vif.monitor_cb.enables, vif.monitor_cb.interrupt);
                analysis_port.write(vif.monitor_cb.interrupt);
                last_sample = {vif.monitor_cb.status, vif.monitor_cb.enables, vif.monitor_cb.interrupt};
            end
        end
    endtask
endclass
