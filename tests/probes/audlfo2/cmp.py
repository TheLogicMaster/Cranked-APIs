import struct, sys, numpy as np
def load(p):
    d=open(p,'rb').read(); return np.array(struct.unpack('<%di'%(len(d)//4),d)).astype(np.int64)
S=load(sys.argv[1]); C=load(sys.argv[2])
s0=int(np.nonzero(S)[0][0]); c0=int(np.nonzero(C)[0][0])
S=S[s0:]; C=C[c0:]
Sp=13230
starts=[0]; t=0
lens=[3*Sp+2205, 3*Sp+2205, 2*26460+2205, 35280+2205, 26460+2205, 2*17640+2205, 3*Sp+2000]
names=['running phase','retrigger+start','delay/ramp','arpeggio','shared','global amp','amp delay']
for n,L in zip(names,lens):
    a=S[t:t+L]; b=C[t:t+L]; m=min(len(a),len(b))
    d=np.nonzero(a[:m]!=b[:m])[0]
    print(f'{n:16s} {"exact" if len(d)==0 else f"{len(d)} differ, first at {d[0]}"}  (energy sim {np.abs(a).sum()//1000} cr {np.abs(b).sum()//1000})')
    t+=L
