import subprocess, os, re, sys, shutil, json
# Resumable driver for the C probe: run, find the first case without output, skip it (skipc.txt), repeat.
# Usage: drive.py sim <cprobe.pdx> <out.txt> | drive.py emu <cprobe.pdx> <out.txt> <emulator runner binary>
# sim needs PLAYDATE_SDK_PATH and xvfb-run; emu runs the runner in the current directory (data in ./appData; see
# "Runner interface" in tests/README.md).
USAGE = 'usage: drive.py sim <cprobe.pdx> <out.txt> | drive.py emu <cprobe.pdx> <out.txt> <emulator runner binary>'
if len(sys.argv) < 4 or sys.argv[1] not in ('sim', 'emu') or (sys.argv[1] == 'emu' and len(sys.argv) < 5):
    sys.exit(USAGE)
mode, pdx, outfile = sys.argv[1], os.path.abspath(sys.argv[2]), sys.argv[3]
runner = sys.argv[4] if len(sys.argv) > 4 else None
SDK = os.environ.get('PLAYDATE_SDK_PATH', '')
names = re.findall(r'T\((t\d*_\w+)\)', open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'src', 'main.c')).read())
data = f'{SDK}/Disk/Data/org.crankedapis.cprobe' if mode == 'sim' else 'appData/org.crankedapis.cprobe'
shutil.rmtree(data if mode == 'sim' else 'appData', ignore_errors=True)
crashed, reasons = [], []
for attempt in range(40):
    if mode == 'sim':
        r = subprocess.run(f'cd {SDK} && timeout 60 xvfb-run -a ./bin/PlaydateSimulator {pdx}', shell=True, capture_output=True, text=True, errors='replace')
    else:
        r = subprocess.run(['timeout', '120', runner, pdx, '3'], capture_output=True, text=True, errors='replace')
    if os.path.exists(data + '/donec.txt'): break
    got = set()
    if os.path.exists(data + '/outc.txt'):
        got = {l.split('\t', 1)[0] for l in open(data + '/outc.txt', errors='replace') if '\t' in l}
    rem = [n for n in names if n not in got and n not in crashed]
    if not rem: break
    crashed.append(rem[0])
    tail = ' / '.join(l for l in (r.stdout + r.stderr).split('\n') if l.strip() and 'sentry' not in l and 'ERROR' not in l)[-200:]
    reasons.append((rem[0], r.returncode, tail))
    os.makedirs(data, exist_ok=True)
    open(data + '/skipc.txt', 'a').write(rem[0] + '\t\n')
shutil.copy(data + '/outc.txt', outfile)
json.dump(reasons, open(outfile + '.aborts.json', 'w'))
for n, rc, t in reasons: print(n, rc, '|', t)
