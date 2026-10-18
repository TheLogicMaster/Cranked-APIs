# Compare the final output (sim_out.raw from simout.sh, cr_out.raw, the final mix from an emulator) by
# section, each aligned on its own onset (the Simulator's disk stream can drop a block or so between sections)
import numpy as np, sys
S=np.fromfile('sim_out.raw',dtype='<i2').reshape(-1,2).astype(np.int64); C=np.fromfile('cr_out.raw',dtype='<i2').reshape(-1,2).astype(np.int64)
s0=np.nonzero(np.abs(S).sum(1))[0][0]; c0=np.nonzero(np.abs(C).sum(1))[0][0]
S=S[s0:]; C=C[c0:]
def onset(z, start):
    nz=np.nonzero(np.abs(z[start:]).sum(1)>0)[0]; return start+nz[0]
names=sys.argv[1].split(',') if len(sys.argv)>1 else ['default','vol 0.5','pan -0.7','vol LFO','pan LFO','clip']
step=float(sys.argv[2]) if len(sys.argv)>2 else 0.6
for k,name in enumerate(names):
    a=int(k*step*44100)
    sa=onset(S,max(0,a-3000)); ca=onset(C,max(0,a-3000))
    n=int(0.45*44100)
    x=S[sa:sa+n]; y=C[ca:ca+n]; d=np.abs(x-y)
    print(f'{name:9s} shift {sa-ca:+5d} differ {np.count_nonzero(d.sum(1)):5d}/{n} max {d.max():5d}  L rms {np.sqrt((x[:,0]**2).mean()):6.0f}/{np.sqrt((y[:,0]**2).mean()):6.0f}  R rms {np.sqrt((x[:,1]**2).mean()):6.0f}/{np.sqrt((y[:,1]**2).mean()):6.0f}')
