`ifndef GUARD_UART_ENV_PKG__SV
`define GUARD_UART_ENV_PKG__SV
`timescale 1ns / 1ps
// Interfaces are static HDL declarations, never members of a class package.
`include "uart_irq_if.sv"
package env_pkg;
    timeunit 1ns;
    timeprecision 1ps;
    import uvm_pkg::*;
    import uart_pkg::*;
    import ahb_pkg::*;
    import uart_regmodel_pkg::*;
`include "uvm_macros.svh"
    `uvm_analysis_imp_decl(_ahb)
    `uvm_analysis_imp_decl(_uart)
    `uvm_analysis_imp_decl(_stimulus)
`include "uart_error_catcher.sv"
`include "uart_irq_monitor.sv"
`include "uart_scoreboard.sv"
`include "uart_environment.sv"
endpackage
`endif
