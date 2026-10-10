`timescale 1ns/1ps
interface uart_if;
    logic tx = 1; // VIP -> DUT RX
    wire rx;      // DUT TX -> VIP
    wire reset_n;
endinterface
