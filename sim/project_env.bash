#!/usr/bin/env bash
_uart_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export UART_IP_VERIF_PATH="$(cd -- "$_uart_script_dir/.." && pwd)"
export AHB_VIP_ROOT="$UART_IP_VERIF_PATH/vip/ahb_vip"
export UART_VIP_ROOT="$UART_IP_VERIF_PATH/vip/uart_vip"
_uart_questa_bin="$(dirname -- "$(command -v vlog)")"
export UVM_HOME="${UVM_HOME:-$(cd -- "$_uart_questa_bin/.." && pwd)/verilog_src/uvm-1.2}"
unset _uart_script_dir _uart_questa_bin
