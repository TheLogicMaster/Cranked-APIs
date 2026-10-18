# Reduce each pattern sample to its phase (px, py): pixel (x, y) shows pattern bit ((x-px)%8, (y-py)%8).
import sys
def phases(rows, s):
    out = []
    for py in range(8):
        for px in range(8):
            if all((s[y*16+x] == '1') == (not (rows[(y-py) % 8] >> (7 - (x-px) % 8)) & 1) for y in range(16) for x in range(16)):
                out.append((px, py))
    return out
def load(p):
    res = {}
    for l in open(p):
        k, s = l.rstrip('\n').split('|'); base, row, v = map(int, k.split())
        rows = [v if i == row else base for i in range(8)]
        res[(base, row, v)] = phases(rows, s)
    return res
if __name__ == '__main__':
    # phase.py <pat3.txt>: prints each case's phases; phase.py <a> <b>: prints only the cases whose phases differ
    if len(sys.argv) not in (2, 3): sys.exit('usage: phase.py <pat3.txt> [<other pat3.txt>]')
    a = load(sys.argv[1]); b = load(sys.argv[2]) if len(sys.argv) == 3 else None
    for k in sorted(a):
        ph = ' '.join('%d,%d' % p for p in a[k]) or 'none'
        if b is None: print('%d %d %d\t%s' % (k + (ph,)))
        elif a[k] != b.get(k):
            print('%d %d %d\t%s\t%s' % (k + (ph, ' '.join('%d,%d' % p for p in b.get(k, [])) or 'none')))
