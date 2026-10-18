import sys
def load(p): return [''.join(format(int(c,16),'04b') for c in r) for r in open(p).read().strip().split('/')]
a=load(sys.argv[1]); b=load(sys.argv[2]); x0,y0,x1,y1,step=map(int,sys.argv[3:8])
for y in range(y0, y1, step):
    print(f'{y:3d}', ''.join('#' if a[y][x]=='1' and b[y][x]=='1' else 'S' if a[y][x]=='1' else 'M' if b[y][x]=='1' else '.' for x in range(x0, x1)))
