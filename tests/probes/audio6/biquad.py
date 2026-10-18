# Fits biquad coefficients to the four low-pass impulse responses in audio6's capture.raw (1 kHz, resonance 0,
# 0.25, 0.75, 0.9; see src/main.c), and compares them with RBJ low-pass filters at several Q.
# Usage: biquad.py <capture.raw>
import struct, math, sys
d=open(sys.argv[1],'rb').read(); n=len(d)//2; L=struct.unpack('<%dh'%n, d[:n*2])
events=[]; quiet=500
for i,v in enumerate(L):
    if v==0: quiet+=1
    else:
        if quiet>=500: events.append(i)
        quiet=0
def fit(h, amp=16000.0):
    # least squares for a1, a2 over the tail
    rows=[(h[k-1], h[k-2], h[k]) for k in range(3, len(h))]
    s11=sum(p*p for p,q,y in rows); s22=sum(q*q for p,q,y in rows); s12=sum(p*q for p,q,y in rows)
    t1=sum(p*y for p,q,y in rows); t2=sum(q*y for p,q,y in rows)
    det=s11*s22-s12*s12
    if det==0: return None
    c1=(t1*s22-t2*s12)/det; c2=(s11*t2-s12*t1)/det
    a1, a2 = -c1, -c2
    b0=h[0]/amp; b1=(h[1]+a1*h[0])/amp; b2=(h[2]+a1*h[1]+a2*h[0])/amp
    return b0,b1,b2,a1,a2
def rbj(f, Q, fs=44100):
    w=2*math.pi*f/fs; al=math.sin(w)/(2*Q); c=math.cos(w); a0=1+al
    b=[(1-c)/2,1-c,(1-c)/2]
    return [x/a0 for x in b]+[-2*c/a0,(1-al)/a0]
for k,r in enumerate((0, 0.25, 0.75, 0.9)):
    if k>=len(events): break
    m=fit(L[events[k]:events[k]+400])
    if m is None: print('res %g: no fit'%r); continue
    print('res %g measured b0 b1 b2 a1 a2:'%r, ' '.join(f'{x:.5f}' for x in m))
    best=[]
    for name,Q in [('Q=0.5',0.5),('Q=0.7071',0.7071),('Q=1',1.0),('Q=1/(2(1-r))',1/(2*(1-r))),('Q=1/(1-r)',1/(1-r)),('Q=0.5+r',0.5+r),('Q=0.7071+r',0.7071+r)]:
        c=rbj(1000,Q); err=sum((x-y)**2 for x,y in zip(m,c))
        best.append((err,name,c))
    best.sort()
    for err,name,c in best[:3]: print(f'   RBJ {name:14s} error {err:.2e}:', ' '.join(f'{x:.5f}' for x in c))
    # solve Q from measured a2: a2 = (1-al)/(1+al) -> al = (1-a2)/(1+a2)
    al=(1-m[4])/(1+m[4]); w=2*math.pi*1000/44100; cw=-m[3]*(1+al)/2
    fr=f'{math.acos(cw)*44100/(2*math.pi):.1f} Hz' if -1<=cw<=1 else 'none'
    print(f'   Q implied by a2: {math.sin(w)/(2*al):.4f};  frequency implied by a1 (with that Q): {fr}')
