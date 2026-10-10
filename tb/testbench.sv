`timescale 1ns/1ps

module tb;
    import uvm_pkg::*;
    import test_pkg::*;

    wire interrupt;

    ahb_if ahb_vif();
    uart_if uart_vif();

    always #5 ahb_vif.HCLK = ~ahb_vif.HCLK;
    
    uart_top dut (
        .HCLK(ahb_vif.HCLK),
        .HRESETN(ahb_vif.HRESETn),
        .HADDR(ahb_vif.HADDR),
        .HTRANS(ahb_vif.HTRANS),
        .HBURST(ahb_vif.HBURST),
        .HSIZE(ahb_vif.HSIZE),
        .HPROT(ahb_vif.HPROT),
        .HWRITE(ahb_vif.HWRITE),
        .HSEL(ahb_vif.HSEL),
        .HWDATA(ahb_vif.HWDATA),
        .HREADYOUT(ahb_vif.HREADYOUT),
        .HRDATA(ahb_vif.HRDATA),
        .HRESP(ahb_vif.HRESP),

        .uart_rxd(uart_vif.tx),
        .uart_txd(uart_vif.rx),

        .interrupt(interrupt)
    );

    initial begin
        ahb_vif.HCLK = 0;
        ahb_vif.HRESETn = 0;
        #100ns;
        ahb_vif.HRESETn = 1;
    end

    initial begin
        uvm_config_db#(virtual ahb_if)::set(
            null, "uvm_test_top", "ahb_vif", ahb_vif
        );

        uvm_config_db#(virtual uart_if)::set(
            null, "uvm_test_top", "uart_vif", uart_vif
        );

        run_test();
    end

    initial begin
        #100ms;
        $fatal(1, "Timeout: Test did not finish within 100ms");
    end
endmodule
