import struct, sys
d=open(sys.argv[1],'rb').read(); n=len(d)//2; L=struct.unpack('<%dh'%n, d[:n*2])
segs=[]; start=None; last=None
for i,x in enumerate(L):
    if abs(x)>100:
        if start is None: start=i
        last=i
    elif start is not None and i-last>1000: segs.append((start,last)); start=None
if start is not None: segs.append((start,last))
base=segs[0][0]
out=[]
for a,b in segs:
    zc=sum(1 for i in range(a+1,b) if L[i-1]<0<=L[i])/((b-a)/44100)
    out.append(f'{(a-base)/44100:.3f}s {"A4" if zc<550 else "E5"}')
print(' | '.join(out))
