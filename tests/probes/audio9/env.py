import struct, sys
d=open(sys.argv[1],'rb').read(); n=len(d)//2; L=struct.unpack('<%dh'%n, d[:n*2])
first=next(i for i,v in enumerate(L) if abs(v)>30)
names=['square','triangle','sine','sample and hold','sawtooth up','sawtooth down']
for k in range(6):
    a=first+int(k*33/30*44100)
    env=[max(abs(x) for x in L[i:i+100]) for i in range(a, a+int(0.4*44100), int(0.01*44100))]
    print(f'{names[k]:16s} envelope every 10 ms (hundreds):', ' '.join(str(v//100) for v in env))
