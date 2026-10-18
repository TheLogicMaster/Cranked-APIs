import re, sys, json
def load(p):
    d, order, last = {}, [], None
    for line in open(p, encoding='utf-8', errors='replace'):
        line = line.rstrip('\n')
        if '\t' in line:
            k, v = line.split('\t', 1); d[k] = v; order.append(k); last = k
        elif last: d[last] += '\\n' + line
    return d, order
sim, order = load(sys.argv[1]); cr, _ = load(sys.argv[2])
res = []
num = re.compile(r'(-?\d+\.\d{3})f|(-?\d+)i')
def nums(s): return [float(a or b) for a, b in num.findall(s)]
for k in order:
    s, c = sim[k], cr.get(k, 'MISSING')
    if s == c: res.append((k, 'same', '')); continue
    if s.startswith('ERR') and c.startswith('ERR'): res.append((k, 'same', 'both error')); continue
    if s.startswith('PIX:') and c.startswith('PIX:'):
        sh, sp = s.split(':', 2)[1:]; ch, cp = c.split(':', 2)[1:]
        if sh != ch: res.append((k, 'diff', f'image size {sh} vs {ch}')); continue
        a, b = sp.replace('/', ''), cp.replace('/', '')
        n = sum(1 for x, y in zip(a, b) if x != y)
        res.append((k, 'same' if n == 0 else 'diff', f'{n}/{len(a)} pixels differ')); continue
    if num.sub('#', s) == num.sub('#', c):
        ns, nc = nums(s), nums(c)
        if all(abs(x - y) <= 1e-3 * max(1, abs(x)) for x, y in zip(ns, nc)):
            res.append((k, 'subtype', '')); continue
    res.append((k, 'diff', ''))
from collections import Counter
cnt = Counter(r[1] for r in res)
print(f"{len(res)} cases: {cnt['same']} same, {cnt['subtype']} integer/float only, {cnt['diff']} differ")
json.dump(res, open(sys.argv[3], 'w'))
for k, st, note in res:
    if st != 'same':
        print(f"- [{st}] {k}: {note}")
        if not sim[k].startswith('PIX'):
            print(f"    sim:     {sim[k][:170]}\n    emu:     {cr.get(k,'MISSING')[:170]}")
