import struct, sys, numpy as np
def load(p):
    d=open(p,'rb').read(); return np.array(struct.unpack('<%di'%(len(d)//4),d)).astype(np.float64)/256
def notes(x):
    s0=int(np.nonzero(x)[0][0])-1
    return [s0+i*26460+i*37 for i in range(12)]
names=['sq','tri','sin','s&h','sawup','sawdn']
def freq_track(x,a):
    # zero crossings (rising) -> instantaneous frequency per period
    seg=x[a:a+22050]; z=np.nonzero((seg[:-1]<0)&(seg[1:]>=0))[0]
    zc=z+(-seg[z])/(seg[z+1]-seg[z])
    f=44100/np.diff(zc); t=zc[1:]
    return t,f
def amp_track(x,a):
    seg=np.abs(x[a:a+22050]); return [int(seg[k:k+441].max()) for k in range(0,22050,441*4)]
if __name__=='__main__':
    S=load(sys.argv[1]); C=load(sys.argv[2])
    ns,nc=notes(S),notes(C)
    for i in range(6):
        ts,fs=freq_track(S,ns[i]); tc,fc=freq_track(C,nc[i])
        pick=lambda t,f: [round(float(np.interp(k,t,f)),1) for k in range(500,22000,1500)]
        print(names[i],'sim',pick(ts,fs)); print(names[i],'cr ',pick(tc,fc))
    for i in range(6,12):
        print(names[i-6],'amp sim',amp_track(S,ns[i])); print(names[i-6],'amp cr ',amp_track(C,nc[i]))
