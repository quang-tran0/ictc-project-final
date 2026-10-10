# UART IP verification implementation plan

> Execution: implement inline using the executing-plans workflow; review the complete branch before pushing.

Goal: complete the supplied Session 19–24 exercise against UART IP Specification
2.0 with self-checking UVM tests, grouped VPlan, measured coverage and reproducible
RTL bug reports.

Sources: the two root PDF files and UVM_QUESTASIM_PROJECT_GUIDE.md, read on
2026-10-10. Baseline commit: 9ccfd39. Branch: feat/uart-uvm-verification.

## Constraints and design

- Never edit, replace, force, or patch RTL. Record SHA-256 hashes and compare at completion.
- Preserve vip/{ahb_vip,uart_vip}, regmodel/register, sequences, tb, testcases,
  sim layout. One UVM class per file; package wrappers define compilation order.
- 100 MHz HCLK; legal word SINGLE / one-beat INCR AHB accesses only. Undefined
  behavior (empty RBR, divisor zero, unsupported transfers) is not a pass criterion.
- AHB monitor publishes completed transfers. UART monitor independently decodes
  both serial directions at configured bit centers. Scoreboard predicts register
  values and compares TX writes / observed TX, observed RX / RBR reads in order.
- Monitor/checker failures are UVM errors; missing, extra and zero-traffic cases
  fail. Tests use bounded waits and count assertions, never blanket error demotion.
- Reset, AHB, baud, TX, RX, FIFO, interrupts, parity are separate VPlan groups.
  Cover both 13x/16x, 5–8 data bits, none/even/odd parity and 1/2 stop bits.
- Known RTL defects stay FAIL in strict regression. A passing unaffected subset
  is reported separately, never advertised as 100% RTL compliance.
- Keep generated simulator binaries/waves/UCDB out of git; commit concise text
  evidence and a generated Vplan.xlsx. Push this branch only; no merge.

## Tasks

### Task 1: Vertical smoke and reusable infrastructure
- [x] Establish failing baseline and write reset/register/TX/RX smoke scenarios.
- [x] Implement legal AHB handshake driver/monitor and UART serializer/decoder.
- [x] Add scoreboard, environment, base test, compile ordering and portable Questa
  discovery. Minimal sequences expose one AHB transfer or one UART frame.
- [x] Run `make -C sim all TESTNAME=uart_smoke_test SEED=1` and debug testbench
  defects from evidence. Require real bus and serial comparisons before PASS.

### Task 2: Spec scenarios and coverage
- [x] Add register model and frontdoor test; reset values: 0,0,0,3,0,0xA,0;
  masks: 1,0xFF,0xFF,0x3F,0x1F. RBR is undefined when empty.
- [x] Add grouped directed tests and randomized duplex tests, including full FIFO
  write rejection, wraparound, all interrupt sources, parity sticky/W1C behavior,
  idle/BUSY/unselected bus cycles and reserved-address error response/recovery.
- [x] Include min/max/low-high divisor boundaries and every frame configuration.
- [x] Add functional covergroups and strict regression exit status/timeouts.
- [x] Run every testcase individually, then seeded regression with coverage ON.

### Task 3: Debug evidence and deliverables
- [x] Minimize each reproducible discrepancy; compare required/observed behavior,
  log test/seed/time/data and affected specification section in bug report/VPlan.
- [x] Merge UCDB and report actual coverage plus exclusions/gaps (encrypted RTL
  may prevent internal code coverage; do not infer it from external coverage).
- [x] Complete Vplan.xlsx with groups, tests, checkers, actual outcomes and bug IDs;
  include implementation estimate, testbench diagram and reproduction commands.
- [x] Review branch, verify hashes and rerun relevant checks.
- Publication: commit the completed evidence and push only the feature branch; no merge.

## Review focus

- Reset during traffic must discard pre-reset pending items, never produce false PASS.
- Back-to-back frames must not disappear between decoder invocations.
- FIFO status is sampled after a bounded settling interval, without DUT internals.
- A late mismatch, UVM_FATAL, timeout or missing marker must make the runner fail.
- Expected data comes from the specification/stimulus, never from DUT output.

## Initial evidence

`make -C sim build` fails before compilation (`vlib: No such file or directory`).
QuestaSim 2021.2_1 executables work directly; resolve executable paths explicitly.
The starting source has empty driver/monitor run phases, missing package files,
duplicate UVM factory macros, and no connected scoreboard.

Planning estimate (engineering effort, not measured elapsed time): requirements
and VPlan 0.5 day; VIP/env/smoke 1.5 days; directed tests/coverage 2 days; debug,
regression and report 1 day. Total 5 working days with a working Questa license.

## Final execution evidence

All 29 testcases executed in 33 runs: 23 PASS, 10 FAIL, 0 UNKNOWN. Three
confirmed RTL bugs remain OPEN. See [VERIFICATION_REPORT.md](VERIFICATION_REPORT.md)
for measured coverage, reproducible failures, assignment acceptance status and limits.
