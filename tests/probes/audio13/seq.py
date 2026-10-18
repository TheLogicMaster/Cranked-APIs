import struct, sys
d=open(sys.argv[1],'rb').read(); n=len(d)//2; L=struct.unpack('<%dh'%n, d[:n*2])
segs=[]; start=None; last=None
for i,x in enumerate(L):
    if abs(x)>100:
        if start is None: start=i
        last=i
    elif start is not None and i-last>1000: segs.append((start,last)); start=None
if start is not None: segs.append((start,last))
base=segs[0][0] if segs else 0
for a,b in segs:
    zc=sum(1 for i in range(a+1,b) if L[i-1]<0<=L[i])
    print(f'  note at {(a-base)/44100:.4f}s, length {(b-a)/44100:.4f}s, peak {max(abs(x) for x in L[a:b+1]):6d}, ~{zc/((b-a)/44100):.0f} Hz')
