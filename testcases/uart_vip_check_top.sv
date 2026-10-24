// Standalone VIP check; no UART RTL is instantiated here. Compile explicitly
// after sim/compile.f and select this top instead of tb. No sim/ edits needed.
// From sim/, after the normal project build:
//   vlog -sv -work work ../testcases/uart_vip_check_top.sv
//   vsim -c uart_vip_check_top -dpicpppath /usr/bin/gcc -coverage \
//     +UVM_TESTNAME=uart_vip_timing_test -do "run -all; quit -f;"
// Catcher guard checks: append ONE of +VIP_CATCH_WRONG_ID,
// +VIP_CATCH_WRONG_COMPONENT, +VIP_CATCH_EXCESS or +VIP_CATCH_MISSING.
// Each guard run must report TEST FAILED; the ordinary run must TEST PASSED.
`timescale 1ns / 1ps
module uart_vip_check_top;
    import uvm_pkg::*;
    import test_pkg::*;
    ahb_if ahb();
    uart_if uart();
    uart_irq_if unused_irq(ahb.HCLK, ahb.HRESETn);
    // Resolve package interface types.
    logic pending = 0, pending_write, pending_error;
    logic [9:0] pending_addr;
    logic [31:0] memory[8];
    int unsigned waits_left = 0;

    always #5ns ahb.HCLK = ~ahb.HCLK;

    assign ahb.HREADYOUT = !(pending && waits_left != 0);
    assign ahb.HRESP = pending && pending_error && waits_left <= 1;
    assign ahb.HRDATA = !pending ? 0 : pending_error ? 32'hdead_beef : memory[pending_addr[4:2]];

    // Independent pipelined AHB slave: accept address/control only at a ready
    // edge; commit write data at the end of the subsequent data phase.
    always @(posedge ahb.HCLK or negedge ahb.HRESETn) begin
        if (!ahb.HRESETn) begin
            pending <= 0;
            waits_left <= 0;
            foreach (memory[i]) memory[i] <= 0;
        end else if (pending && waits_left != 0) waits_left <= waits_left - 1;
        else begin
            if (pending && pending_write && !pending_error)
                memory[pending_addr[4:2]] <= ahb.HWDATA;
            pending <= ahb.HSEL && ahb.HTRANS[1];
            if (ahb.HSEL && ahb.HTRANS[1]) begin
                pending_addr <= ahb.HADDR;
                pending_write <= ahb.HWRITE;
                pending_error <= ahb.HADDR >= 10'h020;
                if (ahb.HADDR >= 10'h020) waits_left <= 3;
                else case (ahb.HADDR[3:2])
                    0: waits_left <= 0;
                    1: waits_left <= 1;
                    2: waits_left <= 3;
                    3: waits_left <= 7;
                endcase
            end
        end
    end

    initial begin
        uart.rx = 1;
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top", "uart_vif", uart);
        uvm_config_db#(virtual ahb_if)::set(null, "uvm_test_top", "ahb_vif", ahb);
        run_test();
    end
    initial begin
        ahb.HCLK = 0;
        ahb.HRESETn = 0;
        repeat (5) @(negedge ahb.HCLK);
        ahb.HRESETn = 1;
    end
endmodule
