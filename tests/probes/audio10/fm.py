import struct, sys, math
d=open(sys.argv[1],'rb').read(); n=len(d)//2; L=struct.unpack('<%dh'%n, d[:n*2])
first=next(i for i,v in enumerate(L) if abs(v)>30)
def freq(seg):
    zc=[i for i in range(1,len(seg)) if seg[i-1]<0<=seg[i]]
    return (len(zc)-1)/((zc[-1]-zc[0])/44100) if len(zc)>2 else 0
for k,dep in enumerate([0.5,1.0,0.1]):
    a=first+int(k*36/30*44100)
    halves=[freq(L[a+int(t*44100)+1000:a+int((t+0.25)*44100)-1000]) for t in [0,0.25,0.5,0.75]]
    print(f'depth {dep}: frequencies in successive LFO half-periods: {[round(f,1) for f in halves]}; ratio high/low {halves[0]/halves[1]:.4f}; semitones each way {12*math.log2(halves[0]/440):+.3f} / {12*math.log2(halves[1]/440):+.3f}')
