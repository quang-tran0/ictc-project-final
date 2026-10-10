# Confirmed UART RTL defects

All three findings reproduce on the original RTL, whose nine file hashes are in
`rtl.sha256`. Neither the RTL nor its signals have been patched or forced.
The protected `.vp` bodies cannot be inspected as source; localization below
states what the interface evidence proves, not an invented internal line.

## UART-001 — TX parity is wrong (OPEN, High)

Requirement: specification §1.6.2.1 and §2.2.4. With PEN=1 and EPS=1, total
ones in the transmitted data and parity bit must be even.

Reproduction:

```bash
make -C sim build COV=ON
make -C sim run TESTNAME=uart_tx_parity_bug_test SEED=1 COV=ON
```

The test initializes 16x sampling, divisor 4, 8E1 (`LCR=0x3B`, checked by AHB
readback), then transmits `0x00`, followed by `0x01`. Each bit is 640 ns.

| Byte | Required parity | Actual pin parity | Payload / stop |
|---|---:|---:|---|
| 0x00 | 0 | 1 | Correct |
| 0x01 | 1 | 0 | Correct |

The UVM monitor reports `TX_PARITY` twice and the test exits nonzero. The same
result is independently decoded from the recorded pin waveform by a Python
implementation that does not consume UVM objects or the RTL algorithm.

```bash
cd sim
wlf2vcd -quiet -o /tmp/uart-tx.vcd log/uart_tx_parity_bug_test_1.wlf
python3 analyze_uart_vcd.py /tmp/uart-tx.vcd --signal tb.uart_vif.rx
```

Evidence: `results/uart_tx_parity_bug_test_1.log` and `results/tx_parity_decode.json`.
The 48-format TX matrix and all five duplex seeds also exercise this defect.
For 8-bit frames, the observed parity is inverted relative to the required
value. The tests do not assert that inversion alone explains every smaller
word-length case. The violated behavior is in the transmitter parity path;
its exact protected source expression is unknown.

## UART-002 — RX parity error is not reported (OPEN, High)

Requirement: specification §2.2.4 PEN/EPS, §2.2.5 IER[4], and §2.2.6 FSR[4].
A bad received parity bit must set the sticky error status, trigger an enabled
interrupt and remain set until software writes one to clear it.

```bash
make -C sim run TESTNAME=uart_rx_parity_bug_test SEED=1 COV=ON
```

The test reads back `LCR=0x3B`, enables `IER[4]`, drives eight zero data bits
and an intentionally wrong parity bit of one, then reads the byte from RBR.
The data is received correctly. FSR reads `0x0A` with bit 4 clear, and IRQ
stays low. Writing zero to FSR consequently cannot demonstrate preservation
of a set flag. Writing one returns zero, **which does not prove W1C works**
because the required initial set state never occurs.

```bash
cd sim
wlf2vcd -quiet -o /tmp/uart-rx.vcd log/uart_rx_parity_bug_test_1.wlf
python3 analyze_uart_vcd.py /tmp/uart-rx.vcd --signal tb.uart_vif.tx
```

Evidence: `results/uart_rx_parity_bug_test_1.log`, `results/rx_parity_decode.json`,
and `results/rx_error_signal_trace.txt`. The external stimulus decoder confirms
data 0x00, even parity expected 0, actual 1, valid stop. Read-only observation
of the existing top-level `s_parrity_error` connection shows no assertion in
this run, localizing the missing indication toward the receiver reporting
path. No exact fault inside the protected modules is claimed.

`uart_parity_error_test` repeats the set/sticky/write-zero/W1C/interrupt scenario
across both oversampling modes, four data widths and even/odd parity. Its
failures remain visible in the strict regression. Set-to-clear and parity-IRQ
assertion coverage are blocked by this bug and must be rerun on corrected RTL.

## UART-003 — back-to-back RX corruption at 13x/divisor 2 (OPEN, High)

Requirement: specification §1.5 and §1.6.2.2. The supported divisor range starts
at one, 13x mode is supported, and 5N1 frames require one stop bit. At a 100 MHz
input clock and divisor two, bit duration is 260 ns and contiguous 5N1 frames
are 1820 ns apart.

```bash
make -C sim run TESTNAME=uart_rx_13x_div2_test SEED=1 COV=ON
```

The first control sends eight `0x17` frames with one extra idle bit between
them: all eight RBR values match. After reset/reinitialization, the second
stream sends eight identical frames with exactly one stop bit and no extra
idle: the first seven values match, but the last is `0x1B` instead of `0x17`.
Both streams start 1 ns away from HCLK edges, ruling out an input-edge race at
the clock sampling edge. Running the initial reproduction without that phase
offset produces the same error.

An independent VCD decode confirms all sixteen wire frames contain `0x17`
and valid stop bits. In the contiguous portion, the existing `rx_wr` connection
produces pulses 1840 ns apart although input frame starts are 1820 ns apart.
This is evidence of accumulating receiver timing lag; it does not reveal the
exact internal counter or state-machine expression in protected RTL.

```bash
cd sim
wlf2vcd -quiet -o /tmp/uart-rx-fast.vcd log/uart_rx_13x_div2_test_1.wlf
python3 analyze_uart_vcd.py /tmp/uart-rx-fast.vcd \
  --signal tb.uart_vif.tx --width 5 --parity none --period-ns 260
```

Evidence: `results/uart_rx_13x_div2_test_1.log`,
`results/rx_fast_decode.json` and `results/rx_fast_signal_trace.txt`.
The current duplex seeds 2, 3, 4, 5 also report RX data mismatches. These are
recorded as UART-003 separately from their TX parity failures.

## Investigation limits

During development, changing the divisor between live, previously configured
scenarios could leave the baud output inactive during the next test's short
wait. The specification gives an initialization sequence but does not specify
phase preservation or a startup bound for live divisor changes. Independent
format/divisor cases therefore start with reset, following Chapter 3; this
observation is not promoted to a confirmed RTL defect or silently counted as
live-reconfiguration coverage. FIFO wraparound, concurrent traffic and BGE
pause/resume are still tested without resetting within their respective cases.
