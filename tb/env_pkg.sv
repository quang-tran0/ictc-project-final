package env_pkg;
    timeunit 1ns; timeprecision 1ps;
    import uvm_pkg::*;
    import ahb_pkg::*;
    import uart_pkg::*;
    `include "uvm_macros.svh"
    `uvm_analysis_imp_decl(_ahb)
    `uvm_analysis_imp_decl(_uart)
    `include "uart_expected_error_catcher.sv"
    `include "uart_scoreboard.sv"
    `include "uart_coverage.sv"
    `include "uart_environment.sv"
endpackage
