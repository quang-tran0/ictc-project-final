package vip_smoke_pkg;
    timeunit 1ns;
    timeprecision 1ps;
    import uvm_pkg::*;
    import ahb_pkg::*;
    import uart_pkg::*;
    import uart_regmodel_pkg::*;
    `include "uvm_macros.svh"
    `include "ahb_smoke_sequence.sv"
    `include "uart_smoke_sequence.sv"
    `include "vip_smoke_test.sv"
endpackage
