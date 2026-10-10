# Independent review and disposition

Review scope: `9ccfd39..ff8d593`, with the assignment, UART specification and
implementation plan. One independent read-only reviewer found four Important
issues and no Critical or Minor issues. No additional review agent was used.

| Finding | Resolution | Verification |
|---|---|---|
| A trailing extra frame could be in flight when the test ended | Monitor tracks each decoder and reports incomplete TX/RX during check_phase | `uart_monitor_tail_test` failed with caught counts 0/0 before the fix, passes with exactly 1/1 after it |
| Full-TX write prediction relied on DUT FSR and did not cover BGE=1 | Test declares intentional rejected writes from its fill stimulus; scoreboard checks exact accepted stream and consumed rejection count | Paused FIFO test plus new `uart_tx_active_full_test` (17 accepted, 3 rejected) |
| An interrupted regression could be reported as a complete passing subset | Manifest stores planned runs/count and complete flag; unfinished runs are UNKNOWN and nonzero | Real report regression failed before fix and passes after; `sim/test_runner.py` |
| Coverage merge included historical UCDBs | Merge inputs come only from the current completed manifest, checked for existence | Self-test leaves an unrelated stale UCDB beside the selected database and verifies it is not included |

Additional checked decisions:

- Reset each independent frame configuration: Chapter 3 specifies initialization;
  live divisor change timing is unspecified. Cost/limit: warm divisor switching
  is not claimed as covered. The observed limitation is recorded in BUG_REPORT.
- Explicit intentional TX rejection is a scenario API, not a general FIFO
  occupancy model. Cost/limit: new overfill scenarios must declare those rejected
  writes; all existing randomized bursts stay below capacity.
- Encrypted RTL: exact internal source fixes are not proposed. The unchanged
  design is delivered with failing bug reproductions, as the user requested.
- Review deferred final evidence/VPlan/coverage judgment while those artifacts
  were being generated; the main agent validates them from the final regression.

No review finding was silently waived. No merge is performed.

The final log-by-log audit found an additional real RX defect (UART-003),
minimized it, checked the stimulus with an independent pin decoder, tested an
idle-gap control, and reran the complete suite including that reproduction.

## Follow-up: UART VIP release notes

The user's notes from a separate UART VIP exercise were checked against this
project before applying them:

- Protocol parity/stop detection already lived in the monitor. Its UVM error
  reporting now lives there too, so a standalone VIP does not need a scoreboard
  to report an invalid frame. The scoreboard remains under `tb/` and compares
  register/data results and the intended RX stimulus.
- `start_delay` defaults to 1 ns in the reusable driver. The DUT tests explicitly
  select zero additional idle and retain their initialization wait, preserving
  contiguous frames and UART-003's timing reproduction.
- Legal randomized frame fields and constraints live in `uart_configuration`.
  The duplex test randomizes that object with its short-run divisor constraint.
- The isolated `uart_vip_contract_test` failed before the changes on four
  assertions (configuration, delay, parity reporting, stop reporting). It then
  passed without a scoreboard and checks zero-delay contiguous timing as well.

One scoped follow-up review found an Important issue in the new test's catcher:
format testing also inherited incomplete-frame error demotion without checking
those counts. A negative variant (`RUNARG=+VIP_TEST_TRAILING_FRAME`) reproduced
false PASS. Catching unfinished-frame errors is now explicitly enabled only by
`uart_monitor_tail_test`; the same negative variant correctly fails with both
incomplete-frame errors. Normal contract and tail tests remain in the full
regression. No review finding is deferred. See `results/vip_review_red_green.txt`.

`report_rx_parity_errors` defaults to enabled in the VIP. DUT scenarios explicitly
disable only that report because they inject expected malformed RX frames;
monitor detection remains active and the scoreboard compares every parity flag
against per-frame stimulus intent. DUT TX reports and stop-error reports remain
active. No catchers are installed in DUT compliance tests.
