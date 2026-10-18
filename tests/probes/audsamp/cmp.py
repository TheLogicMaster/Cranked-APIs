import struct, numpy as np, sys
def load(p):
    d=open(p,'rb').read(); x=np.array(struct.unpack('<%di'%(len(d)//4),d)).astype(np.int64); nz=np.nonzero(x)[0]; return x[nz[0]:] if len(nz) else x
S=load(sys.argv[1]); C=load(sys.argv[2])
names=['no loop','loop C4','2000 Hz','3500 Hz cap','stereo','8-bit','unity','ADSR','end beyond']
for i in range(9):
    a=S[i*44100:(i+1)*44100]; b=C[i*44100:(i+1)*44100]; m=min(len(a),len(b))
    d=np.nonzero(a[:m]!=b[:m])[0]
    ea=np.nonzero(a)[0]; eb=np.nonzero(b)[0]
    print(f'{names[i]:12s}', 'exact' if len(d)==0 else f'{len(d)} differ from {d[0]}', ' sound len sim', (ea[-1]-ea[0]) if len(ea) else 0, 'cr', (eb[-1]-eb[0]) if len(eb) else 0)
