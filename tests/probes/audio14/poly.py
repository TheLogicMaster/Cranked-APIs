import struct, sys, math
d=open(sys.argv[1],'rb').read(); n=len(d)//2; L=struct.unpack('<%dh'%n, d[:n*2])
def mag(x, f):
    c=sum(v*math.cos(2*math.pi*f*i/44100) for i,v in enumerate(x)); s=sum(v*math.sin(2*math.pi*f*i/44100) for i,v in enumerate(x))
    return 2*math.hypot(c,s)/len(x)
starts=[]; i=0
while i < n:
    if abs(L[i])>50: starts.append(i); i+=int(1.5*44100)
    else: i+=1
names={261.6:'C4',329.6:'E4',392.0:'G4',523.3:'C5'}
for k,a in enumerate(starts[:2]):
    print(f'playback {k+1} ({k+1} voice{"s" if k else ""}):')
    for label,t0,t1 in [('C4 alone (steps 0-96)',0.05,0.45),('E4+G4 chord (steps 96-144)',0.52,0.72),('G4 after E4 ends (144-288)',0.78,1.45),('C5 (480-504)',2.505,2.62)]:
        x=L[a+int(t0*44100):a+int(t1*44100)]
        if not x: continue
        print(f'   {label:28s}', ' '.join(f'{nm}:{mag(x,f):6.0f}' for f,nm in names.items()))
