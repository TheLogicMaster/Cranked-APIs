import struct, sys
def load(p):
    d=open(p,'rb').read(); n=len(d)//4; v=struct.unpack('<%dh'%(n*2), d[:n*4]); return v[0::2], v[1::2]
L,R=load(sys.argv[1]); M=[max(abs(a),abs(b)) for a,b in zip(L,R)]
segs=[]; start=None; last=None
for i,x in enumerate(M):
    if x>300:
        if start is None: start=i
        last=i
    elif start is not None and i-last>3000: segs.append((start,last)); start=None
if start is not None: segs.append((start,last))
names=['sample vol (0.5, 0.25)','synth sine vol (1, 0), note vol 0.5','sample, channel volume 0.5','sample, channel pan -1']
for k,(a,b) in enumerate(segs):
    print(f"  {names[k] if k<4 else k:40s} left peak {max(abs(x) for x in L[a:b+1]):6d}  right peak {max(abs(x) for x in R[a:b+1]):6d}")
