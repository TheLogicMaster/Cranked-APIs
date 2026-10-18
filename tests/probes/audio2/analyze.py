import struct, sys, math
def load(p):
    d=open(p,'rb').read(); n=len(d)//2; return struct.unpack('<%dh'%n, d[:n*2])
def segments(L, thr=150, gap=3000):
    segs=[]; start=None; last=None
    for i,x in enumerate(L):
        if abs(x)>thr:
            if start is None: start=i
            last=i
        elif start is not None and i-last>gap: segs.append((start,last)); start=None
    if start is not None: segs.append((start,last))
    return segs
def env(seg, win=441):
    return [max(abs(x) for x in seg[i:i+win]) for i in range(0, len(seg)-win, win)]
L=load(sys.argv[1]); rate=44100
names=['square 0.3','sine 0.3','triangle 0.3','sawtooth 0.3','noise 0.3','square 1.0','square ADSR 0.05/0.1/0.5/0.2']
for k,(a,b) in enumerate(segments(L)):
    seg=L[a:b+1]
    zc=sum(1 for i in range(1,len(seg)) if (seg[i-1]<0)!=(seg[i]<0))
    mid=seg[len(seg)//3: len(seg)//3+4410]
    rms=math.sqrt(sum(x*x for x in mid)/len(mid)) if mid else 0
    e=env(seg)
    print(f"{names[k] if k<len(names) else k:32s} start {a/rate:.3f}s length {len(seg)/rate:.3f}s peak {max(abs(x) for x in seg):5d} rms {rms:7.0f} freq~{zc/2/(len(seg)/rate):.0f}Hz")
    print('    envelope (10 ms peaks):', ' '.join(str(v//100) for v in e[:8]), '...', ' '.join(str(v//100) for v in e[-8:]))
