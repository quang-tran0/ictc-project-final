#!/usr/bin/env python3
"""Independent UART pin decoder for fixed-format minimal bug reproductions.

Example: wlf2vcd -o /tmp/tx.vcd log/uart_tx_parity_bug_test_1.wlf
         python3 analyze_uart_vcd.py /tmp/tx.vcd --signal tb.uart_vif.rx
VCD time unit must be 1ps. Does not use UVM objects or RTL implementation.
"""
import argparse
from bisect import bisect_right
from pathlib import Path


def read_signal(path, signal):
    scope, transitions = [], []
    symbol = None
    now = 0
    ps_units = False
    for line in path.read_text().splitlines():
        words = line.split()
        if line.strip() == '1ps':
            ps_units = True
        if line.startswith('$scope'):
            scope.append(words[2])
        elif line.startswith('$upscope'):
            scope.pop()
        elif line.startswith('$var') and '.'.join(scope + [words[4]]) == signal:
            symbol = words[3]
        elif line.startswith('#'):
            now = int(line[1:])
        elif symbol and line[1:] == symbol and line[0] in '01xz':
            if not transitions or transitions[-1][1] != line[0]:
                transitions.append((now, line[0]))
    if not ps_units or not transitions:
        raise ValueError('Requires a 1ps VCD with the requested signal')
    return transitions


def decode(transitions, width, parity, stops, period_ps):
    times = [t for t, _ in transitions]
    def level(time):
        return transitions[bisect_right(times, time)-1][1]
    ready = 0
    records = []
    for i, (start, value) in enumerate(transitions):
        if not i or value != '0' or transitions[i-1][1] != '1' or start < ready:
            continue
        data = sum(int(level(start + (3+2*b)*period_ps//2)) << b for b in range(width))
        expected = (data.bit_count() % 2) ^ (parity == 'odd')
        observed = level(start + (3+2*width)*period_ps//2)
        stop_ok = all(level(start + (5+2*width+2*s)*period_ps//2) == '1' for s in range(stops))
        ready = start + (1+width+1+stops)*period_ps
        records.append(dict(start_ns=start/1000, data=f'0x{data:02x}', expected_parity=expected,
                            actual_parity=observed, parity_ok=observed == str(expected), stop_ok=stop_ok))
    return records


def main():
    import json
    p = argparse.ArgumentParser()
    p.add_argument('vcd', type=Path)
    p.add_argument('--signal', default='tb.uart_vif.rx')
    p.add_argument('--width', type=int, default=8)
    p.add_argument('--parity', choices=('even','odd'), default='even')
    p.add_argument('--stops', type=int, default=1)
    p.add_argument('--period-ns', type=int, default=640)
    args = p.parse_args()
    records = decode(read_signal(args.vcd,args.signal),args.width,args.parity,args.stops,args.period_ns*1000)
    print(json.dumps(records,indent=2))
    if not records:
        raise SystemExit('No frames decoded')


if __name__ == '__main__':
    main()
