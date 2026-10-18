#!/usr/bin/env python3
"""Compares a probe suite run with the probes' expected output (see README.md).

Usage: compare.py <data folder> [--probes name ...] [--json report.json] [--diff] [--against <data folder>]
       compare.py --bundles <Data folder> [...]

<data folder> is the suite's data folder after a run: it holds suite.txt and p/<name>/ for each probe (on a Playdate,
Data/org.crankedapis.suite/; in the Simulator, Disk/Data/org.crankedapis.suite/ in the SDK folder; in an emulator,
wherever it keeps the bundle's data). Each probe's outputs are paired with the files in its expected/ folder:

- an expected file and an output with the same name;
- an expected file named sim_<name> and an output named <name>;
- otherwise, when one expected text file is left: the one output file left (console.txt and error.txt aside), else
  out.txt, else console.txt.

Lines are compared after replacing host addresses (0x...) with ADDR on both sides; `<word>` in an expected line
(`<year>`, `<n>`) matches any text. With --against, the outputs are compared with another run's data folder instead of
expected/ (for example a device run against a Simulator run of the same suite).

Each probe gets one result: same, differs (with the number of lines that differ), missing (no output to compare),
or not run; a probe in variable.txt that differs is reported as varies (its output depends on time or speed).
How the probe ended (exit, idle, frame-limit, update-error, ...) comes from suite.txt, and error.txt is
reported when present. --diff prints the first differing lines of each probe.

With --bundles, the folder is the whole Data folder of a device (or the Simulator's Disk/Data) after running the
bundles build_bundles.py made: each probe's outputs are in org.crankedapis.b.<name>/. A file console.txt in that
folder, if you saved the probe's console log there, is paired as in the suite.
"""
import argparse, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROBES = os.path.normpath(os.path.join(HERE, '..', 'probes'))
TEXT = ('.txt', '.json', '.csv', '.log')
ADDR = re.compile(r'0x[0-9a-fA-F]+')
PLACEHOLDER = re.compile(r'<[a-z][a-z ]*>')


def read_lines(path):
    with open(path, 'rb') as f:
        data = f.read().decode('utf-8', 'replace')
    return [ADDR.sub('ADDR', line) for line in data.replace('\r\n', '\n').split('\n')]


def line_matches(expected, actual):
    if expected == actual:
        return True
    if not PLACEHOLDER.search(expected):
        return False
    parts = PLACEHOLDER.split(expected)
    return re.fullmatch('.+?'.join(re.escape(p) for p in parts), actual) is not None


def compare_files(expected, actual):
    """(number of differing lines, [(line number, expected, actual)] for the first few)."""
    a, b = read_lines(expected), read_lines(actual)
    while a and a[-1] == '':
        a.pop()
    while b and b[-1] == '':
        b.pop()
    bad = []
    for i in range(max(len(a), len(b))):
        x = a[i] if i < len(a) else None
        y = b[i] if i < len(b) else None
        if x is None or y is None or not line_matches(x, y):
            bad.append((i + 1, x, y))
    return len(bad), bad[:5]


def outputs(folder):
    out = []
    for root, _, files in os.walk(folder):
        for f in files:
            if f.endswith(TEXT):
                out.append(os.path.relpath(os.path.join(root, f), folder))
    return sorted(out)


def pair(expected_files, output_files):
    """[(expected name, output name)], with output None when nothing pairs."""
    results = [o for o in output_files if o not in ('console.txt', 'error.txt')]
    pairs, left_exp, used = [], [], set()
    for e in expected_files:
        # the same name, or the name without the sim_ prefix the recorded copies often have (sim_out3.txt: out3.txt)
        for o in (e, e[4:] if e.startswith('sim_') else None):
            if o in output_files and o not in used:
                pairs.append((e, o))
                used.add(o)
                break
        else:
            left_exp.append(e)
    left_out = [o for o in results if o not in used]
    if len(left_exp) == 1:
        e = left_exp[0]
        if len(left_out) == 1:
            pairs.append((e, left_out[0]))
        elif 'out.txt' in left_out:  # the usual name of a probe's result; the other files are what it wrote to test
            pairs.append((e, 'out.txt'))
        elif e in ('sim_log.txt', 'sim.txt') and 'console.txt' in output_files:
            pairs.append((e, 'console.txt'))
        else:
            pairs.append((e, None))
    else:
        pairs += [(e, None) for e in left_exp]
    return pairs


def variable():
    out = {}
    path = os.path.join(HERE, 'variable.txt')
    for line in open(path, encoding='utf-8') if os.path.exists(path) else []:
        line = line.strip()
        if line and not line.startswith('#'):
            name, _, why = line.partition(' ')
            out[name] = why
    return out


def suite_log(data):
    ended = {}
    path = os.path.join(data, 'suite.txt')
    if os.path.exists(path):
        for line in open(path, encoding='utf-8', errors='replace'):
            parts = line.split()
            if len(parts) >= 2 and parts[0] != 'suite' and parts[1] not in ('started', 'interrupted'):
                ended[parts[0]] = ' '.join(parts[1:])
    return ended


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('data')
    ap.add_argument('--probes', nargs='*')
    ap.add_argument('--json')
    ap.add_argument('--diff', action='store_true')
    ap.add_argument('--against', help='compare with this run instead of expected/')
    ap.add_argument('--bundles', action='store_true', help='the folder is a Data folder with one folder per bundle')
    a = ap.parse_args()

    def probe_folder(root, name):
        return os.path.join(root, 'org.crankedapis.b.' + name) if a.bundles else os.path.join(root, 'p', name)

    names = a.probes
    if a.bundles:
        found = sorted(d[len('org.crankedapis.b.'):] for d in os.listdir(a.data) if d.startswith('org.crankedapis.b.'))
        names = names or found
        ended = {n: 'bundle' for n in found}
    else:
        ended = suite_log(a.data)
        if not names:
            names = list(ended) if ended else sorted(os.listdir(os.path.join(a.data, 'p')))

    varies = variable()
    report, counts = [], {}
    for name in names:
        folder = probe_folder(a.data, name)
        ref = probe_folder(a.against, name) if a.against else os.path.join(PROBES, name, 'expected')
        entry = {'name': name, 'ended': ended.get(name, 'not run'), 'files': []}
        if os.path.exists(os.path.join(folder, 'error.txt')):
            entry['error'] = open(os.path.join(folder, 'error.txt'), encoding='utf-8', errors='replace').read().strip()
        if not os.path.isdir(folder) or name not in ended and not a.probes:
            entry['result'] = 'not run'
        elif not os.path.isdir(ref):
            entry['result'] = 'no reference'
        else:
            got = outputs(folder)
            want = [f for f in outputs(ref) if not (a.against and f == 'error.txt')]
            differs = missing = 0
            for e, o in pair(want, got):
                if o is None:
                    entry['files'].append({'expected': e, 'result': 'missing'})
                    missing += 1
                    continue
                n, first = compare_files(os.path.join(ref, e), os.path.join(folder, o))
                entry['files'].append({'expected': e, 'output': o, 'differing_lines': n, 'first': first})
                differs += n > 0
            if not entry['files']:
                entry['result'] = 'missing'
            elif differs:
                entry['result'] = 'varies' if name in varies else 'differs'
            elif missing:
                entry['result'] = 'missing'
            else:
                entry['result'] = 'same'
        counts[entry['result']] = counts.get(entry['result'], 0) + 1
        report.append(entry)

    for entry in report:
        detail = ', '.join(f"{f['expected']}: {f['result'] if 'result' in f else str(f['differing_lines']) + ' lines'}"
                           for f in entry['files'] if f.get('result') == 'missing' or f.get('differing_lines'))
        line = f"{entry['name']:<14} {entry['result']:<10} {entry['ended']:<22} {detail}"
        if 'error' in entry:
            line += f"  error: {entry['error'].splitlines()[0][:100]}"
        print(line.rstrip())
        if a.diff:
            for f in entry['files']:
                for num, x, y in f.get('first', []):
                    print(f"    {f['expected']}:{num}\n      expected: {x}\n      output:   {y}")
    print(', '.join(f'{v} {k}' for k, v in sorted(counts.items())), file=sys.stderr)
    if a.json:
        with open(a.json, 'w') as f:
            json.dump({'counts': counts, 'probes': report}, f, indent=1)


if __name__ == '__main__':
    main()
