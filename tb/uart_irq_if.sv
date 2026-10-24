`ifndef UART_IRQ_IF_SV
`define UART_IRQ_IF_SV
`timescale 1ns / 1ps
interface uart_irq_if(input logic clk, input logic reset_n);
    wire interrupt;
    wire [4:0] status, enables;
    wire tx_wr, tx_rd, rx_wr, rx_rd;
    wire [7:0] tx_data, rx_data;
    wire apb_access, apb_write;
    wire [9:0] apb_addr;
    wire [31:0] apb_data;
    wire parity_pulse;
    clocking monitor_cb @(posedge clk);
        default input #1step;
        input reset_n, interrupt, status, enables;
    endclocking
endinterface
`endif
