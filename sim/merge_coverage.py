#!/usr/bin/env python3
"""Merge only completed run databases from the current regression manifest."""
import json
from pathlib import Path
import subprocess
import sys


def databases(results):
    if not results.get('complete') or len(results['runs']) != results.get('planned_count'):
        raise ValueError('Cannot merge incomplete regression coverage')
    if results['coverage'] != 'ON':
        raise ValueError('Regression was not compiled and run with coverage')
    paths = []
    for run in results['runs']:
        if run['timeout'] or run['status'] == 'UNKNOWN':
            raise ValueError(f'Incomplete simulation: {run["test"]}')
        path = Path(run['log']).with_suffix('.ucdb')
        if not path.is_file():
            raise ValueError(f'Missing coverage database: {path}')
        paths.append(str(path))
    if not paths:
        raise ValueError('No coverage inputs')
    return paths


if __name__ == '__main__':
    inputs = databases(json.loads(Path('regress.json').read_text()))
    Path('coverage_inputs.txt').write_text('\n'.join(inputs)+'\n')
    subprocess.run([sys.argv[1], 'merge', 'UART_MERGE.ucdb', *inputs], check=True)
