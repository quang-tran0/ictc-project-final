// Isolated model check: no RTL or AHB VIP. Do not use this define in a DUT build.
+define+UART_RAL_MODEL_ONLY
+incdir+${UART_IP_VERIF_PATH}/regmodel/register
+incdir+${UART_IP_VERIF_PATH}/regmodel
+incdir+${UART_IP_VERIF_PATH}/regmodel/checks
${UART_IP_VERIF_PATH}/regmodel/register/uart_register_pkg.sv
${UART_IP_VERIF_PATH}/regmodel/uart_regmodel_pkg.sv
${UART_IP_VERIF_PATH}/regmodel/checks/uart_ral_self_check.sv
