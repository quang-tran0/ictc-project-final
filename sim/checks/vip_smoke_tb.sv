module vip_smoke_tb;
    timeunit 1ns;
    timeprecision 1ps;
    import uvm_pkg::*;
    import vip_smoke_pkg::*;
    ahb_if ahb();
    uart_if uart();
    always #5ns ahb.HCLK = ~ahb.HCLK;
`ifdef VIP_USE_DUT
    uart_top dut(.HCLK(ahb.HCLK), .HRESETN(ahb.HRESETn),
        .HADDR(ahb.HADDR), .HTRANS(ahb.HTRANS), .HBURST(ahb.HBURST),
        .HSIZE(ahb.HSIZE), .HPROT(ahb.HPROT), .HWRITE(ahb.HWRITE),
        .HSEL(ahb.HSEL), .HWDATA(ahb.HWDATA), .HREADYOUT(ahb.HREADYOUT),
        .HRDATA(ahb.HRDATA), .HRESP(ahb.HRESP),
        .uart_rxd(1'b1), .uart_txd(), .interrupt());
`else
    ahb_smoke_slave slave(ahb);
`endif
`ifdef VIP_USE_DUT
    always @(posedge ahb.HCLK)
        if ($test$plusargs("VIP_TRACE") && $time < 1us)
            $display("BUS %0t rst=%b sel=%b trans=%b addr=%h wr=%b wd=%h ready=%b resp=%b rd=%h APB addr=%h wd=%h sel=%b en=%b wr=%b",
                     $time, ahb.HRESETn, ahb.HSEL, ahb.HTRANS, ahb.HADDR,
                     ahb.HWRITE, ahb.HWDATA, ahb.HREADYOUT, ahb.HRESP, ahb.HRDATA,
                     dut.paddr, dut.pwdata, dut.psel, dut.penable, dut.pwrite);
`endif
    initial begin
        ahb.HCLK = 0;
        ahb.HRESETn = 0;
        uart.rx = 1;
        #22ns;
        ahb.HRESETn = 1;
    end
    initial begin
        uvm_config_db #(virtual ahb_if)::set(null, "uvm_test_top", "ahb_vif", ahb);
        uvm_config_db #(virtual uart_if)::set(null, "uvm_test_top", "uart_vif", uart);
        run_test("vip_smoke_test");
    end
    initial begin
        #100ms;
        $fatal(1, "VIP smoke timeout: missing response or observation");
    end
`ifndef VIP_USE_DUT
    // Prove that zero-wait traffic actually overlaps, rather than just completing.
    final begin
        if (slave.consecutive_count == 0 || slave.wait_count == 0)
            $error("Smoke did not exercise pipeline and wait states");
    end
`endif
endmodule
