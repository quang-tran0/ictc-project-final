#!/usr/bin/env python3
"""Checks the result gate with real transcript content; no simulator required."""
from check_log import classify

PASS = '# UVM_INFO @ 20: test [TEST_STATUS] TEST PASSED\n'
assert classify(PASS + '# UVM_ERROR : 0\n# UVM_FATAL : 0\n') == 'PASS'
assert classify(PASS + '# UVM_ERROR @ 30: tb [MISMATCH] data\n') == 'FAIL'
assert classify(PASS + '# UVM_FATAL : 1\n') == 'FAIL'
assert classify(PASS + '# ** Error: simulator crashed\n') == 'FAIL'
assert classify(PASS + 'TEST FAILED\n') == 'FAIL'
assert classify(PASS + PASS) == 'UNKNOWN'
assert classify('') == 'UNKNOWN'
assert classify('TEST PASSED mentioned in a help message') == 'UNKNOWN'
print('Result gate: 8 checks passed')

from pathlib import Path
from tempfile import TemporaryDirectory
import sys
from regress import execute, read_config
from analyze_uart_vcd import decode

with TemporaryDirectory() as tmp:
    root = Path(tmp)
    cfg = root / 'test.cfg'
    cfg.write_text('cov = on\ntimeout_seconds = 5\ntc_list {\n uart_smoke_test, run_times=2, run_opts=+N=8 ;\n}\n')
    assert read_config(cfg) == ('ON', 5, [('uart_smoke_test', 2, '+N=8')])
    cfg.write_text('cov = on\ntimeout_seconds = 5\ntc_list {\n bad_test, run_times=0, run_opts= ;\n}\n')
    try:
        read_config(cfg)
    except ValueError:
        pass
    else:
        raise AssertionError('Zero-run configuration was accepted')
    output = root / 'process.log'
    assert execute([sys.executable, '-c', 'raise SystemExit(3)'], output, 2) == (3, False)
    assert execute([sys.executable, '-c', 'import time; time.sleep(10)'], output, 1) == (124, True)

for byte in (0, 1, 0x55, 0xa6, 0xff):
    for bad in (False, True):
        bit_values = [0] + [(byte >> bit) & 1 for bit in range(8)] + [(byte.bit_count() % 2) ^ bad] + [1]
        transitions = [(0, '1')]
        for i, value in enumerate(bit_values):
            if str(value) != transitions[-1][1]:
                transitions.append((1000 + i*640000, str(value)))
        records = decode(transitions, 8, 'even', 1, 640000)
        assert len(records) == 1 and int(records[0]['data'], 16) == byte
        assert records[0]['parity_ok'] != bad and records[0]['stop_ok']
print('Configuration, exit status, timeout and independent decoder checks passed')
