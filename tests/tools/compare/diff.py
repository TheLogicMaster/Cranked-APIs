import re, sys
def load(p):
    d = {}
    for line in open(p):
        line = line.rstrip('\n')
        if '\t' in line:
            k, v = line.split('\t', 1); d[k] = v
    return d
sim, cr = load(sys.argv[1]), load(sys.argv[2])
num = re.compile(r'(-?\d+\.\d{4})([if])')
def norm(v, keep_type):
    return num.sub(lambda m: m.group(1) + (m.group(2) if keep_type else ''), v)
def close(a, b):
    na, nb = num.findall(a), num.findall(b)
    if num.sub('#', a) != num.sub('#', b) or len(na) != len(nb): return False
    return all(abs(float(x) - float(y)) <= 1e-3 * max(1, abs(float(x))) for (x, _), (y, _) in zip(na, nb))
same = typed = 0; diffs = []
for k in sim:
    s, c = sim[k], cr.get(k)
    if s == c: same += 1; continue
    if c is not None and close(s, c):
        if norm(s, False) == norm(c, False) or close(s, c): typed += 1; continue
    diffs.append((k, s, c))
print(f"{len(sim)} cases: {same} identical, {typed} equal except integer/float subtype, {len(diffs)} differ")
for k, s, c in diffs: print(f"- {k}\n    sim:     {s}\n    emu:     {c}")
