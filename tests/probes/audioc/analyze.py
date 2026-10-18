import struct, sys
def load(p):
    d=open(p,'rb').read(); n=len(d)//4; v=struct.unpack('<%dh'%(n*2), d[:n*4]); return v[0::2], v[1::2]
def segments(L, thr=300, gap=2000):
    segs=[]; start=None; last=None
    for i,x in enumerate(L):
        if abs(x)>thr:
            if start is None: start=i
            last=i
        elif start is not None and i-last>gap:
            segs.append((start,last)); start=None
    if start is not None: segs.append((start,last))
    return segs
def describe(L, a, b, rate=44100):
    seg=L[a:b+1]; zc=sum(1 for i in range(1,len(seg)) if (seg[i-1]<0)!=(seg[i]<0))
    freq=zc/2/(len(seg)/rate) if len(seg) else 0
    return f"start {a/rate:.3f}s length {len(seg)/rate:.3f}s peak {max(abs(x) for x in seg)} freq~{freq:.0f}Hz"
L,R=load(sys.argv[1])
print(sys.argv[1], 'frames', len(L))
for a,b in segments(L): print('  ', describe(L,a,b))
