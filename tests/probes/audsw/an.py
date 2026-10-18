import sys, math, numpy as np
sys.path.insert(0,'.'); from seg import load
L=np.array(load(sys.argv[1]),dtype=float)
s0=int(np.nonzero(L)[0][0]); print('start',s0)
for i in range(60):
    f=20*2**(i/6); a=s0+i*5512
    w=L[a+600:a+4000]; n=len(w)
    t=np.arange(n)
    hs=[]
    for k in range(1,200):
        if k*f>22050: break
        c=np.exp(-2j*math.pi*k*f*t/44100)
        hs.append(abs((w*c).sum())*2/n)
    nh=sum(1 for h in hs if h>30)
    print(f'{i:2d} {f:8.1f} min {w.min():7.0f} max {w.max():7.0f} mean {w.mean():7.0f} h1 {hs[0]:7.0f} nh {nh:3d} last {[round(x) for x in hs[max(0,nh-2):nh+1]]}')
