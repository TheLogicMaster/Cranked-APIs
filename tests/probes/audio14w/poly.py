import struct, sys, math
d=open(sys.argv[1],'rb').read(); n=len(d)//4; L=[v >> 8 for v in struct.unpack('<%di'%n, d[:n*4])]  # 32-bit capture, scaled to 16 bits
def mag(x, f):
    c=sum(v*math.cos(2*math.pi*f*i/44100) for i,v in enumerate(x)); s=sum(v*math.sin(2*math.pi*f*i/44100) for i,v in enumerate(x))
    return 2*math.hypot(c,s)/len(x)
# the first playback starts at the first sample above 50; the second (started 95 frames later, about 3.17 s) at the
# first sample above 50 from 3 s after that, when the first has ended
def onset(i):
    while i < n and abs(L[i])<=50: i+=1
    return i
starts=[onset(0)]; starts.append(onset(starts[0]+3*44100)); starts=[a for a in starts if a<n]
names={261.6:'C4',329.6:'E4',392.0:'G4',523.3:'C5'}
for k,a in enumerate(starts[:2]):
    print(f'playback {k+1} ({k+1} voice{"s" if k else ""}):')
    for label,t0,t1 in [('C4 alone (steps 0-96)',0.05,0.45),('E4+G4 chord (steps 96-144)',0.52,0.72),('G4 after E4 ends (144-288)',0.78,1.45),('C5 (480-504)',2.505,2.62)]:
        x=L[a+int(t0*44100):a+int(t1*44100)]
        if not x: continue
        print(f'   {label:28s}', ' '.join(f'{nm}:{mag(x,f):6.0f}' for f,nm in names.items()))
