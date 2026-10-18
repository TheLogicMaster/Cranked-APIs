import struct, math, sys
def load(p):
    d=open(p,'rb').read(); n=len(d)//4; v=struct.unpack('<%dh'%(n*2), d[:n*4]); return v[0::2], v[1::2]
def segments(L, thr=300, gap=3000):
    segs=[]; start=None; last=None
    for i,x in enumerate(L):
        if abs(x)>thr:
            if start is None: start=i
            last=i
        elif start is not None and i-last>gap: segs.append((start,last)); start=None
    if start is not None: segs.append((start,last))
    return segs
def sinefit(x, f=440.0, rate=44100):
    n=len(x); c=sum(v*math.cos(2*math.pi*f*i/rate) for i,v in enumerate(x)); s=sum(v*math.sin(2*math.pi*f*i/rate) for i,v in enumerate(x))
    a=2*c/n; b=2*s/n; amp=math.hypot(a,b)
    res=math.sqrt(sum((v-(a*math.cos(2*math.pi*f*i/rate)+b*math.sin(2*math.pi*f*i/rate)))**2 for i,v in enumerate(x))/n)
    return amp, res
names=['8-bit mono','ADPCM mono','ADPCM stereo']
for path in sys.argv[1:]:
    L,R=load(path); print(path)
    for k,(a,b) in enumerate(segments(L)):
        mid=slice(a+2000, a+2000+8820)
        al,rl=sinefit(L[mid]); ar,rr=sinefit(R[mid])
        print(f"  {names[k] if k<3 else k:13s} length {(b-a+1)/44100:.3f}s  left: amplitude {al:6.0f} residual {rl:5.0f} ({100*rl/max(al,1):4.1f}%)  right: amplitude {ar:6.0f} residual {rr:5.0f}")
