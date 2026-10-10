#!/usr/bin/env python3
"""Compile once, run only configured tests and report strict reproducible results."""
import argparse
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import time
from check_log import classify


def read_config(path):
    text = re.sub(r'#[^\n]*', '', path.read_text())
    cov = re.search(r'^\s*cov\s*=\s*(on|off)\s*$', text, re.M | re.I)
    timeout = re.search(r'^\s*timeout_seconds\s*=\s*(\d+)\s*$', text, re.M)
    entries = re.search(r'tc_list\s*\{(.*?)\}', text, re.S)
    if not cov or not timeout or not entries:
        raise ValueError('Configuration requires cov, timeout_seconds and tc_list')
    tests = []
    for line in entries.group(1).splitlines():
        if not line.strip():
            continue
        m = re.fullmatch(r'\s*(\w+)\s*,\s*run_times=(\d+)\s*,\s*run_opts=(.*?)\s*;\s*', line)
        if not m or int(m[2]) < 1:
            raise ValueError(f'Invalid testcase row: {line}')
        tests.append((m[1], int(m[2]), m[3]))
    if not tests:
        raise ValueError('Empty regression')
    return cov[1].upper(), int(timeout[1]), tests


def execute(cmd, output, timeout):
    with output.open('w') as stream:
        process = subprocess.Popen(cmd, stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            return process.wait(timeout=timeout), False
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            return 124, True


def make_report(results):
    lines = ['UART strict regression', f"Configuration: {results['config']}",
             f"Coverage: {results['coverage']}", f"Base seed: {results['base_seed']}"]
    counts = {key: sum(r['status'] == key for r in results['runs']) for key in ('PASS', 'FAIL', 'UNKNOWN')}
    unfinished = max(0, results.get('planned_count', len(results['runs'])) - len(results['runs']))
    counts['UNKNOWN'] += unfinished
    complete = results.get('complete', False) and not unfinished
    lines.append(f"Complete: {complete}; unexecuted: {unfinished}")
    lines.append(f"Total: {results.get('planned_count',len(results['runs']))} PASS: {counts['PASS']} FAIL: {counts['FAIL']} UNKNOWN: {counts['UNKNOWN']}")
    for row in results['runs']:
        lines.append(f"{row['status']:7} {row['test']} seed={row['seed']} exit={row['exit_code']} timeout={row['timeout']} log={row['log']}")
    Path('regress.rpt').write_text('\n'.join(lines)+'\n')
    Path('regress.json').write_text(json.dumps(results, indent=2)+'\n')
    print('\n'.join(lines), flush=True)
    return 0 if complete and results['runs'] and not counts['FAIL'] and not counts['UNKNOWN'] else 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--file', default='regress.cfg')
    parser.add_argument('-r', '--report', action='store_true')
    parser.add_argument('--seed', type=int, default=1)
    args = parser.parse_args()
    os.chdir(Path(__file__).resolve().parent)
    if args.report:
        results = json.loads(Path('regress.json').read_text())
        for row in results['runs']:
            log = Path(row['log'])
            row['status'] = classify(log.read_text(errors='replace')) if log.exists() else 'UNKNOWN'
            if row['timeout'] or row['exit_code'] != 0:
                row['status'] = 'FAIL' if row['status'] != 'UNKNOWN' else 'UNKNOWN'
        return make_report(results)
    cov, timeout, tests = read_config(Path(args.file))
    Path('log').mkdir(exist_ok=True)
    results = {'config': args.file, 'coverage': cov, 'base_seed': args.seed, 'planned_count': sum(n for _, n, _ in tests),
               'complete': False, 'planned_runs': [dict(test=name,seed=args.seed+i,options=opts)
                   for name,n,opts in tests for i in range(n)], 'runs': []}
    Path('regress.json').write_text(json.dumps(results, indent=2)+'\n')
    code, timed_out = execute(['make', 'build', f'COV={cov}'], Path('build.log'), timeout)
    if code != 0:
        print('Build failed; see sim/build.log', flush=True)
        return 2
    for name, repetitions, opts in tests:
        for repeat in range(repetitions):
            seed = args.seed + repeat
            log = Path('log') / f'{name}_{seed}.log'
            console = Path('log') / f'{name}_{seed}.console.log'
            started = time.monotonic()
            code, timed_out = execute(['make', 'run', f'TESTNAME={name}', f'SEED={seed}',
                                      f'COV={cov}', f'RUNARG={opts}'], console, timeout)
            status = classify(log.read_text(errors='replace')) if log.exists() else 'UNKNOWN'
            if timed_out or code != 0:
                status = 'FAIL' if status != 'UNKNOWN' else 'UNKNOWN'
            row = dict(test=name, seed=seed, status=status, exit_code=code, timeout=timed_out,
                       elapsed_seconds=round(time.monotonic()-started, 3), log=str(log), options=opts)
            results['runs'].append(row)
            Path('regress.json').write_text(json.dumps(results, indent=2)+'\n')
            print(f'{status:7} {name} seed={seed} ({row["elapsed_seconds"]}s)', flush=True)
    results['complete'] = True
    return make_report(results)


if __name__ == '__main__':
    raise SystemExit(main())
