`timescale 1ns/1ps
interface ahb_if;
    logic HCLK = 0;
    logic HRESETn = 0;
    logic [9:0] HADDR;
    logic [2:0] HBURST;
    logic HMASTLOCK;
    logic [3:0] HPROT;
    logic [2:0] HSIZE;
    logic [1:0] HTRANS;
    logic HSEL;
    logic [31:0] HWDATA, HRDATA;
    logic HWRITE, HREADYOUT, HRESP;
    wire interrupt;

    // Sample the bus immediately before the accepting edge, avoiding NBA races.
    clocking mon_cb @(posedge HCLK);
        default input #1step;
        input HRESETn, HADDR, HBURST, HSIZE, HTRANS, HSEL;
        input HWDATA, HRDATA, HWRITE, HREADYOUT, HRESP;
    endclocking
endinterface
