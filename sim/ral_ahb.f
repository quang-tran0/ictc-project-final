// Optional adapter check, once the existing AHB package compiles.
+incdir+${UART_IP_VERIF_PATH}/regmodel/register
+incdir+${UART_IP_VERIF_PATH}/regmodel
+incdir+${UART_IP_VERIF_PATH}/regmodel/checks
-f ${AHB_VIP_ROOT}/ahb_vip.f
${UART_IP_VERIF_PATH}/regmodel/register/uart_register_pkg.sv
${UART_IP_VERIF_PATH}/regmodel/uart_regmodel_pkg.sv
${UART_IP_VERIF_PATH}/regmodel/checks/uart_ral_self_check.sv
