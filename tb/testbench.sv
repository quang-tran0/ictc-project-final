`timescale 1ns/1ps
module tb;
    import uvm_pkg::*;
    import test_pkg::*;
    `include "uvm_macros.svh"
    ahb_if ahb_vif();
    uart_if uart_vif();
    uart_if checker_vif();
    assign checker_vif.rx=checker_vif.tx;
    assign checker_vif.reset_n=ahb_vif.HRESETn;
    always #5ns ahb_vif.HCLK = ~ahb_vif.HCLK;
    assign uart_vif.reset_n = ahb_vif.HRESETn;
    uart_top dut (
        .HCLK(ahb_vif.HCLK), .HRESETN(ahb_vif.HRESETn),
        .HADDR(ahb_vif.HADDR), .HTRANS(ahb_vif.HTRANS),
        .HBURST(ahb_vif.HBURST), .HSIZE(ahb_vif.HSIZE),
        .HPROT(ahb_vif.HPROT), .HWRITE(ahb_vif.HWRITE),
        .HSEL(ahb_vif.HSEL), .HWDATA(ahb_vif.HWDATA),
        .HREADYOUT(ahb_vif.HREADYOUT), .HRDATA(ahb_vif.HRDATA), .HRESP(ahb_vif.HRESP),
        .uart_rxd(uart_vif.tx), .uart_txd(uart_vif.rx), .interrupt(ahb_vif.interrupt)
    );
    initial begin
        uvm_config_db#(virtual ahb_if)::set(null,"uvm_test_top","ahb_vif",ahb_vif);
        uvm_config_db#(virtual uart_if)::set(null,"uvm_test_top","uart_vif",uart_vif);
        uvm_config_db#(virtual uart_if)::set(null,"uvm_test_top","checker_vif",checker_vif);
        run_test();
    end
    initial begin
        int timeout_us;
        timeout_us = 500000;
        void'($value$plusargs("TIMEOUT_US=%d",timeout_us));
        #(timeout_us * 1us);
        `uvm_fatal("TEST_TIMEOUT", "Simulation deadline exceeded")
    end
endmodule
