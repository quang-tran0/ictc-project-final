`ifndef UART_SEQ_PKG_SV
`define UART_SEQ_PKG_SV
`timescale 1ns / 1ps
package seq_pkg;
    timeunit 1ns;
    timeprecision 1ps;
    import uvm_pkg::*;
    import ahb_pkg::*;
    import uart_pkg::*;
    import env_pkg::*;
`include "uvm_macros.svh"
`include "uart_ahb_sequence.sv"
`include "uart_rx_sequence.sv"
`include "uart_setup_sequence.sv"
`include "uart_tx_sequence.sv"
`include "uart_random_sequence.sv"
endpackage
`endif
