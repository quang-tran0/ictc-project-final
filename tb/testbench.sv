`timescale 1ns / 1ps
module tb;
    timeunit 1ns;
    timeprecision 1ps;
    import uvm_pkg::*;
    import test_pkg::*;
    ahb_if ahb_vif();
    uart_if uart_vif();
    uart_irq_if irq_vif(ahb_vif.HCLK, ahb_vif.HRESETn);
    always #5ns ahb_vif.HCLK = ~ahb_vif.HCLK;

    uart_top dut(
        .HCLK(ahb_vif.HCLK), .HRESETN(ahb_vif.HRESETn),
        .HADDR(ahb_vif.HADDR), .HTRANS(ahb_vif.HTRANS),
        .HBURST(ahb_vif.HBURST), .HSIZE(ahb_vif.HSIZE),
        .HPROT(ahb_vif.HPROT), .HWRITE(ahb_vif.HWRITE),
        .HSEL(ahb_vif.HSEL), .HWDATA(ahb_vif.HWDATA),
        .HREADYOUT(ahb_vif.HREADYOUT), .HRDATA(ahb_vif.HRDATA), .HRESP(ahb_vif.HRESP),
        .uart_rxd(uart_vif.tx), .uart_txd(uart_vif.rx), .interrupt(irq_vif.interrupt)
    );

    // Observe FIFO requests at the clock edge for occupancy checks.
    assign irq_vif.status = {
        dut.parrity_error_status, dut.rx_empty_status, dut.rx_full_status,
        dut.tx_empty_status, dut.tx_full_status
    };
    assign irq_vif.enables = {
        dut.en_parrity_error, dut.en_rx_fifo_empty, dut.en_rx_fifo_full,
        dut.en_tx_fifo_empty, dut.en_tx_fifo_full
    };
    assign irq_vif.tx_wr = dut.tx_wr;
    assign irq_vif.tx_rd = dut.tx_rd;
    assign irq_vif.rx_wr = dut.rx_wr;
    assign irq_vif.rx_rd = dut.rx_rd;
    assign irq_vif.tx_data = dut.tx_data_in;
    assign irq_vif.rx_data = dut.rx_data_in;
    assign irq_vif.apb_access = dut.psel && dut.penable && dut.pready;
    assign irq_vif.apb_write = dut.pwrite;
    assign irq_vif.apb_addr = dut.paddr;
    assign irq_vif.apb_data = dut.pwdata;
    assign irq_vif.parity_pulse = dut.s_parrity_error;

    initial begin
        ahb_vif.HCLK = 0;
        ahb_vif.HRESETn = 0;
        repeat (10) @(negedge ahb_vif.HCLK);
        ahb_vif.HRESETn = 1;
    end

    initial begin
        uvm_config_db#(virtual ahb_if)::set(null, "uvm_test_top", "ahb_vif", ahb_vif);
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top", "uart_vif", uart_vif);
        uvm_config_db#(virtual uart_irq_if)::set(null, "uvm_test_top", "uart_irq_vif", irq_vif);
        run_test();
    end
endmodule
