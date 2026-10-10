`ifndef UART_REGISTER_PKG__SV
`define UART_REGISTER_PKG__SV

package uart_register_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "uart_mdr_reg.sv"
    `include "uart_dll_reg.sv"
    `include "uart_dlh_reg.sv"
    `include "uart_lcr_reg.sv"
    `include "uart_ier_reg.sv"
    `include "uart_fsr_reg.sv"
    `include "uart_tbr_reg.sv"
    `include "uart_rbr_reg.sv"
endpackage : uart_register_pkg

`endif
