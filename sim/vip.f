-f ${AHB_VIP_ROOT}/ahb_vip.f
-f ${UART_VIP_ROOT}/uart_vip.f
+incdir+${UART_IP_VERIF_PATH}/regmodel/register
+incdir+${UART_IP_VERIF_PATH}/regmodel
+incdir+${UART_IP_VERIF_PATH}/sim/checks
${UART_IP_VERIF_PATH}/regmodel/register/uart_register_pkg.sv
${UART_IP_VERIF_PATH}/regmodel/uart_regmodel_pkg.sv
${UART_IP_VERIF_PATH}/sim/checks/vip_smoke_pkg.sv
${UART_IP_VERIF_PATH}/sim/checks/ahb_smoke_slave.sv
${UART_IP_VERIF_PATH}/sim/checks/vip_smoke_tb.sv
