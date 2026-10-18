import struct, math, sys, collections
d=open(sys.argv[1],'rb').read(); n=len(d)//2; L=struct.unpack('<%dh'%n, d[:n*2])
def segments(L, thr=150, gap=3000):
    segs=[]; start=None; last=None
    for i,x in enumerate(L):
        if abs(x)>thr:
            if start is None: start=i
            last=i
        elif start is not None and i-last>gap: segs.append((start,last)); start=None
    if start is not None: segs.append((start,last))
    return segs
segs=segments(L); print('segments', len(segs))
def phasefit(x, f=440.0, rate=44100):
    c=sum(v*math.cos(2*math.pi*f*i/rate) for i,v in enumerate(x)); s=sum(v*math.sin(2*math.pi*f*i/rate) for i,v in enumerate(x))
    return math.atan2(c, s)
# overdrive: transfer curve
a,b=segs[0]; x=L[a+2000:a+6410]; ph=phasefit(x)
pairs=[(16384*math.sin(2*math.pi*440*i/44100+ph), v) for i,v in enumerate(x)]
print('overdrive (gain 2, limit 0.5): output peak', max(abs(v) for _,v in pairs))
for target in [0,2000,4000,6000,8000,10000,12000,14000,16000]:
    near=[v for u,v in pairs if abs(u-target)<300]
    if near: print(f'   input {target:6d} -> output {round(sum(near)/len(near)):6d}')
# bitcrusher amount 0.5
a,b=segs[1]; x=L[a+2000:a+8000]
vals=sorted(set(x)); diffs=collections.Counter(q-p for p,q in zip(vals,vals[1:]))
print('bitcrusher amount 0.5: distinct values', len(vals), 'most common step between levels', diffs.most_common(3), 'peak', max(abs(v) for v in x))
print('   sample values:', x[:20])
# undersampling 0.5
a,b=segs[2]; x=L[a+2000:a+6000]
runs=[]; r=1
for i in range(1,len(x)):
    if x[i]==x[i-1]: r+=1
    else: runs.append(r); r=1
print('bitcrusher undersampling 0.5: run lengths', collections.Counter(runs).most_common(4), 'peak', max(abs(v) for v in x))
