# Usage: segs.py <capture.raw>: the sample positions where each note's envelope changes slope
import struct, sys, numpy as np
d=open(sys.argv[1] if len(sys.argv) > 1 else 'sim.raw','rb').read(); L=np.array(struct.unpack('<%dh'%(len(d)//2),d)).astype(np.int64)
s0=next(i for i,x in enumerate(L) if x!=0)
def note(i): return s0-1+i*15037
if __name__=='__main__':
  for i in list(range(20))+[22,23]:
    a=note(i); x=-L[a:a+15000]
    dx=np.diff(x); ddx=np.diff(dx)
    br=[j+1 for j in range(len(ddx)) if abs(ddx[j])>1]
    # compress consecutive
    out=[]; 
    for b in br:
        if not out or b-out[-1]>2: out.append(b)
    print(i, 'blockoff', a%256, 'breaks', out[:12])
