import sys
def load(p):
    rows=open(p).read().strip().split('/')
    return [''.join(format(int(c,16),'04b') for c in r) for r in rows]
a=load(sys.argv[1]); b=load(sys.argv[2])
pts=[(x,y) for y in range(240) for x in range(400) if a[y][x]!=b[y][x]]
if not pts: print('identical'); sys.exit()
xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
x0,x1,y0,y1=min(xs),max(xs),min(ys),max(ys)
print(f'{len(pts)} differ in x {x0}-{x1}, y {y0}-{y1}  (# both, S Simulator only, M emulator only)')
for y in range(max(0,y0-1), min(239,y1+1)+1):
    print(f'{y:3d}', ''.join('#' if a[y][x]=='1' and b[y][x]=='1' else 'S' if a[y][x]=='1' else 'M' if b[y][x]=='1' else '.' for x in range(max(0,x0-2), min(399,x0+110))))
