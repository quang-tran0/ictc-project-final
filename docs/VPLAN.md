# UART verification plan results

29 testcases; 33 runs: 23 PASS, 10 FAIL, 0 UNKNOWN.

All planned tests were executed. RTL compliance is not closed: parity and RX frame-timing defects remain open.
See `Vplan.xlsx` for checkers, references, seeds and bug details.

| ID | Group | Testcase | Status | Bug |
|---|---|---|---|---|
| REG-01 | 1. Register | `uart_register_reset_test` | PASS | — |
| REG-02 | 1. Register | `uart_register_access_test` | PASS | — |
| REG-03 | 1. Register | `uart_regmodel_test` | PASS | — |
| AHB-01 | 2. AHB access | `uart_ahb_transfer_test` | PASS | — |
| AHB-02 | 2. AHB access | `uart_ahb_idle_test` | PASS | — |
| AHB-03 | 2. AHB access | `uart_reserved_access_test` | PASS | — |
| BAUD-01 | 3. Baud generator | `uart_baud_test` | PASS | — |
| BAUD-02 | 3. Baud generator | `uart_baud_disable_test` | PASS | — |
| TX-01 | 4. UART TX | `uart_tx_format_test` | FAIL | UART-001 |
| TX-02 | 4. UART TX | `uart_tx_data_test` | PASS | — |
| RX-01 | 5. UART RX | `uart_rx_format_test` | PASS | — |
| RX-02 | 5. UART RX | `uart_rx_data_test` | PASS | — |
| RX-03 | 5. UART RX | `uart_rx_13x_div2_test` | FAIL | UART-003 |
| FIFO-01 | 6. FIFO | `uart_tx_fifo_test` | PASS | — |
| FIFO-02 | 6. FIFO | `uart_tx_active_full_test` | PASS | — |
| FIFO-03 | 6. FIFO | `uart_rx_fifo_test` | PASS | — |
| IRQ-01 | 7. Interrupt | `uart_irq_mask_test` | PASS | — |
| IRQ-02 | 7. Interrupt | `uart_irq_tx_empty_test` | PASS | — |
| IRQ-03 | 7. Interrupt | `uart_irq_tx_full_test` | PASS | — |
| IRQ-04 | 7. Interrupt | `uart_irq_rx_empty_test` | PASS | — |
| IRQ-05 | 7. Interrupt | `uart_irq_rx_full_test` | PASS | — |
| PAR-01 | 8. Parity error | `uart_parity_error_test` | FAIL | UART-002 |
| PAR-02 | 8. Parity error | `uart_parity_disabled_test` | PASS | — |
| PAR-03 | 8. Parity error | `uart_tx_parity_bug_test` | FAIL | UART-001 |
| PAR-04 | 8. Parity error | `uart_rx_parity_bug_test` | FAIL | UART-002 |
| SYS-01 | 9. Integration and checker | `uart_smoke_test` | PASS | — |
| SYS-02 | 9. Integration and checker | `uart_duplex_random_test` | FAIL | UART-001; UART-003 |
| SYS-03 | 9. Integration and checker | `uart_reset_traffic_test` | PASS | — |
| SYS-04 | 9. Integration and checker | `uart_monitor_tail_test` | PASS | — |
