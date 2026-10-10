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

from analyze_uart_vcd import read_signal
with TemporaryDirectory() as tmp:
    path = Path(tmp) / 'one_bit.vcd'
    path.write_text('$timescale\n 1ps\n$end\n$scope module top $end\n$var reg 1 ! rx $end\n$upscope $end\n$enddefinitions $end\n#0\nb1 !\n#10\nb0 !\n')
    assert read_signal(path, 'top.rx') == [(0, '1'), (10, '0')]
print('VCD single-bit vector encoding check passed')

from regress import make_report
from merge_coverage import databases
import os
with TemporaryDirectory() as tmp:
    previous = Path.cwd()
    try:
        os.chdir(tmp)
        report = {'config':'suite.cfg','coverage':'ON','base_seed':1,'planned_count':2,'complete':False,
                  'runs':[{'test':'one','seed':1,'exit_code':0,'timeout':False,'status':'PASS','log':'one.log'}]}
        assert make_report(report) != 0
        Path('one.ucdb').touch()
        Path('stale_other_seed.ucdb').touch()
        report['planned_count']=1; report['complete']=True
        assert databases(report) == ['one.ucdb']
        report['complete']=False
        try:
            databases(report)
        except ValueError:
            pass
        else:
            raise AssertionError('Incomplete coverage accepted')
    finally:
        os.chdir(previous)
print('Interrupted regression and stale coverage checks passed')

# A failed build must invalidate an earlier successful manifest before reporting.
import shutil
import subprocess
with TemporaryDirectory() as tmp:
    root=Path(tmp)
    for script in ('regress.py','check_log.py'):
        shutil.copy(Path(__file__).resolve().parent/script,root/script)
    (root/'regress.cfg').write_text('cov = off\ntimeout_seconds = 5\ntc_list {\n uart_smoke_test, run_times=2, run_opts= ;\n}\n')
    (root/'regress.json').write_text('{"complete": true, "planned_count": 1, "runs": []}')
    (root/'make').write_text('#!/bin/sh\nexit 7\n')
    (root/'make').chmod(0o755)
    env=dict(os.environ, PATH=str(root)+os.pathsep+os.environ['PATH'])
    result=subprocess.run([sys.executable,str(root/'regress.py')],env=env,capture_output=True,text=True)
    assert result.returncode==2
    import json
    manifest=json.loads((root/'regress.json').read_text())
    assert not manifest['complete'] and manifest['planned_count']==2
print('Failed build invalidates previous manifest')

transitions=[(0,'1')]
for frame in range(8):
    for bit,value in enumerate([0,1,1,1,0,1,1]):  # 5N1, payload 0x17
        if str(value)!=transitions[-1][1]:
            transitions.append((1000+(frame*7+bit)*260000,str(value)))
records=decode(transitions,5,'none',1,260000)
assert len(records)==8 and all(r['data']=='0x17' and r['stop_ok'] for r in records)
print('No-parity back-to-back decoder check passed')
