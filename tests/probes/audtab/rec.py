import sys, json
from fractions import Fraction as Fr
from seg import load
# Usage: rec.py <capture.raw> [onset offset]: reads the sampled waveform back from a capture into tables.json
OFF=int(sys.argv[2]) if len(sys.argv)>2 else -1
L=load(sys.argv[1])
steps=[Fr(3,4),Fr(3,2),Fr(3),Fr(7),Fr(13),Fr(25),Fr(49),Fr(97)]
s0=next(i for i,x in enumerate(L) if x!=0)
tables={}
for i in range(17):
    size=256 if i<16 else 1024; st=steps[i%8] if i<16 else Fr(1)
    a=s0+i*11025
    # onset: first nonzero near a
    on=next(j for j in range(a-50,a+2000) if L[j]!=0)
    best=None
    for o in [OFF]:
        st0=on+o; T={}; bad=0
        for n in range(2000,8000):
            ph=n*st
            if ph.denominator!=1: continue
            idx=int(ph)%size; v=L[st0+n]
            if idx in T and T[idx]!=v: bad+=1
            T[idx]=v
        if best is None or bad<best[0]: best=(bad,o,T)
    bad,o,T=best
    name=('saw' if i<8 else 'tri' if i<16 else 'sin')+str(i%8 if i<16 else '')
    print(name,'onset',on-a,'offset',o,'conflicts',bad,'entries',len(T),'max',max(T.values()),'min',min(T.values()), 'T0..4',[T.get(k) for k in range(5)])
    tables[name]=[T.get(k) for k in range(size)]
json.dump(tables,open('tables.json','w'))
