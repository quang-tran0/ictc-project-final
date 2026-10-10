`ifndef UART_REGMODEL_PKG__SV
`define UART_REGMODEL_PKG__SV

package uart_regmodel_pkg;
    import uvm_pkg::*;
    import uart_register_pkg::*;
    `include "uvm_macros.svh"
`ifndef UART_RAL_MODEL_ONLY
    import ahb_pkg::*;
`endif

    `include "uart_reg_block.sv"
    // Isolated structural builds can omit the currently uncompilable AHB VIP.
    // Normal DUT builds must not define UART_RAL_MODEL_ONLY.
`ifndef UART_RAL_MODEL_ONLY
    `include "uart_reg_adapter.sv"
`endif
endpackage : uart_regmodel_pkg

`endif
