package uart_pkg;
    timeunit 1ns; timeprecision 1ps;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "uart_define.sv"
    `include "uart_transaction.sv"
    `include "uart_configuration.sv"
    `include "uart_sequencer.sv"
    `include "uart_driver.sv"
    `include "uart_monitor.sv"
    `include "uart_agent.sv"
endpackage