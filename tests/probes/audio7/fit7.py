import struct, math, sys
d=open(sys.argv[1],'rb').read(); n=len(d)//2; L=struct.unpack('<%dh'%n, d[:n*2])
fs=44100
def onsets(L, count, gap=0.4):
    ev=[]; i=0
    while i < len(L) and len(ev) < count:
        if L[i]!=0: ev.append(i); i+=int(gap*fs)
        else: i+=1
    return ev
ev=onsets(L, 7)
def fit(h, amp=16000.0):
    rows=[(h[k-1], h[k-2], h[k]) for k in range(3, 500)]
    s11=sum(p*p for p,q,y in rows); s22=sum(q*q for p,q,y in rows); s12=sum(p*q for p,q,y in rows)
    t1=sum(p*y for p,q,y in rows); t2=sum(q*y for p,q,y in rows)
    det=s11*s22-s12*s12; c1=(t1*s22-t2*s12)/det; c2=(s11*t2-s12*t1)/det
    a1,a2=-c1,-c2
    return [h[0]/amp,(h[1]+a1*h[0])/amp,(h[2]+a1*h[1]+a2*h[0])/amp,a1,a2]
def rbj(kind, f, Q, gainDb, fs=44100):
    A=10**(gainDb/40); w=2*math.pi*f/fs; c=math.cos(w); s=math.sin(w); al=s/(2*Q)
    if kind=='bp': b=[al,0,-al]; a=[1+al,-2*c,1-al]
    elif kind=='notch': b=[1,-2*c,1]; a=[1+al,-2*c,1-al]
    elif kind=='peq': b=[1+al*A,-2*c,1-al*A]; a=[1+al/A,-2*c,1-al/A]
    elif kind=='ls':
        sq=2*math.sqrt(A)*al
        b=[A*((A+1)-(A-1)*c+sq),2*A*((A-1)-(A+1)*c),A*((A+1)-(A-1)*c-sq)]; a=[(A+1)+(A-1)*c+sq,-2*((A-1)+(A+1)*c),(A+1)+(A-1)*c-sq]
    else:
        sq=2*math.sqrt(A)*al
        b=[A*((A+1)+(A-1)*c+sq),-2*A*((A-1)+(A+1)*c),A*((A+1)+(A-1)*c-sq)]; a=[(A+1)-(A-1)*c+sq,2*((A-1)-(A+1)*c),(A+1)-(A-1)*c-sq]
    return [b[0]/a[0],b[1]/a[0],b[2]/a[0],a[1]/a[0],a[2]/a[0]]
Q=1/(0.7116*0.5)
for k,(kind,name) in enumerate([('bp','band-pass'),('notch','notch'),('peq','PEQ gain 6'),('ls','low shelf gain 6'),('hs','high shelf gain 6')]):
    h=L[ev[k]:ev[k]+500]; m=fit(h)
    print(f'{name:18s} measured:', ' '.join(f'{x:+.5f}' for x in m))
    best=[]
    for gname,g in [('6 dB',6),('linear 6 (15.6 dB)',20*math.log10(6)),('0 dB',0)]:
        for Qname,QQ in [('Q as LP/HP',Q),('Q=0.7071',0.7071),('S=1 slope',None)]:
            if QQ is None:
                if kind not in ('ls','hs'): continue
                A=10**(g/40); QQ=1/math.sqrt((A+1/A)*(1/1-1)+2)
            r=rbj(kind,1000,QQ,g); err=sum((x-y)**2 for x,y in zip(m,r)); best.append((err,gname,Qname,r))
    best.sort()
    e,gname,Qname,r=best[0]
    print(f'   best cookbook: gain {gname}, {Qname}, error {e:.1e}:', ' '.join(f'{x:+.5f}' for x in r))
# ring modulator on the sine
a=ev[5]; x=L[a+2000:a+2000+4410]
best=None
for ph in [i*math.pi/36 for i in range(72)]:
    for ph2 in [0]:
        pass
amp=max(abs(v) for v in x)
print('ring mod: peak', amp, '; zero crossings per second', round(sum(1 for i in range(1,len(x)) if (x[i-1]<0)!=(x[i]<0))/(len(x)/fs)))
# spectrum peaks at 340 and 540 Hz expected for 440 x 100
def mag(f): 
    c=sum(v*math.cos(2*math.pi*f*i/fs) for i,v in enumerate(x)); s=sum(v*math.sin(2*math.pi*f*i/fs) for i,v in enumerate(x))
    return 2*math.hypot(c,s)/len(x)
print('   spectrum:', {f: round(mag(f)) for f in [100,340,440,540,880]})
# delay tap
a=ev[6]; seg=L[a:a+5000]
print('tap: nonzero positions relative to first output:', [(j,seg[j]) for j in range(len(seg)) if seg[j]!=0][:6])
