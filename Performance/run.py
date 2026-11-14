#!/usr/bin/env python3
"""Rebuild programs, simulate the unchanged CPU, verify and summarize results."""
import csv
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent

def run(args):
    return subprocess.run(args, cwd=ROOT, check=True, text=True, capture_output=True)

def main():
    (HERE / 'results').mkdir(exist_ok=True)
    (HERE / 'results/summary.csv').unlink(missing_ok=True)
    build = ROOT / 'build' / 'performance'
    build.mkdir(parents=True, exist_ok=True)
    run([sys.executable, str(HERE / 'generate.py')])
    rtl = sorted(p for p in ROOT.glob('*/*.sv')) + sorted((ROOT / 'ALU/blocks').glob('*.sv'))
    compiler = shlex.split(os.environ.get('IVERILOG', 'iverilog'))
    simulator = shlex.split(os.environ.get('VVP', 'vvp'))
    compile_args = compiler + ['-g2012', '-Wall', '-s', 'tb_Performance', '-o', str(build / 'performance.vvp'), str(HERE / 'tb/Performance_tb.sv')] + [str(p) for p in rtl]
    compiled = run(compile_args)
    log = compiled.stdout + compiled.stderr
    rows = []
    for item in json.loads((HERE / 'programs/manifest.json').read_text()):
        args = simulator + [str(build / 'performance.vvp'), f"+name={item['name']}", f"+count={item['retired']}", f"+stores={item['stores']}", f"+words={item['words']}", f"+stop={item['stop_pc']}"]
        if '--waves' in sys.argv:
            args.append('+waves')
        result = run(args)
        print(result.stdout.strip())
        log += result.stdout + result.stderr
        with (HERE / 'results' / (item['name'] + '.csv')).open() as f:
            row = next(csv.DictReader(f))
        for field in ('retired', 'stores', 'branches', 'taken', 'jumps'):
            assert int(row[field]) == item[field], (field, row, item)
        assert int(row['mispredictions']) == item['branches'] - item['taken']
        assert int(row['predictions']) == item['branches']
        rows.append(row)
    # Independent analytical expectations for the fixed benchmark sources.
    expected = [(37, 33, 0, 0, 0, 0), (37, 33, 0, 0, 0, 0),
                (61, 49, 8, 0, 0, 0), (64, 37, 0, 14, 5, 2)]
    fields = ('cycles', 'retired', 'load_use_stalls', 'branches', 'mispredictions', 'jumps')
    for row, wanted in zip(rows, expected):
        assert tuple(int(row[k]) for k in fields) == wanted, row
    with (HERE / 'results/summary.csv').open('w') as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader(); writer.writerows(rows)
    (HERE / 'results/run.log').write_text(log)
    version = subprocess.run(compiler + ['-V'], text=True, capture_output=True)
    metadata = {'simulator': version.stdout.splitlines()[0], 'rtl_sha256': {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in rtl}}
    (HERE / 'results/provenance.json').write_text(json.dumps(metadata, indent=2) + '\n')
    print('PASS: architectural checks and analytical cycle expectations for all four programs')

if __name__ == '__main__':
    try:
        main()
    except subprocess.CalledProcessError as e:
        print(e.stdout or '', file=sys.stderr)
        print(e.stderr or '', file=sys.stderr)
        raise
