import struct, sys, math
d=open(sys.argv[1],'rb').read(); n=len(d)//2; L=struct.unpack('<%dh'%n, d[:n*2])
def fit(h):
    rows=[(h[k-1], h[k-2], h[k]) for k in range(3, 300)]
    s11=sum(p*p for p,q,y in rows); s22=sum(q*q for p,q,y in rows); s12=sum(p*q for p,q,y in rows)
    t1=sum(p*y for p,q,y in rows); t2=sum(q*y for p,q,y in rows)
    det=s11*s22-s12*s12
    if det == 0: return None
    c1=(t1*s22-t2*s12)/det; c2=(s11*t2-s12*t1)/det
    a1,a2=-c1,-c2
    al=(1-a2)/(1+a2); cw=-a1*(1+al)/2
    return math.acos(max(-1,min(1,cw)))*44100/(2*math.pi) if -1<=cw<=1 else None
starts=[]; i=0
while i < n:
    if L[i]!=0: starts.append(i); i+=int(0.2*44100)
    else: i+=1
first=starts[0]
for s in starts[:8]:
    f=fit(L[s:s+300])
    print(f'impulse at {(s-first)/44100:.3f}s after the first: implied filter frequency {f:.0f} Hz' if f else f'impulse at {(s-first)/44100:.3f}s: no fit')
