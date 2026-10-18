import struct, re, collections
def load(p):
    d=open(p,'rb').read(); n=len(d)//2; return struct.unpack('<%dh'%n, d[:n*2])
def events(p):
    ev={}
    for l in open(p):
        m=re.match(r'(.*) at capture frame (\d+)', l.strip())
        if m: ev.setdefault(m.group(1), []).append(int(m.group(2)))
    return ev
def describe(L, a, span):
    seg=L[a:a+span]
    nz=[i for i,v in enumerate(seg) if abs(v)>60]
    if not nz: return 'silent'
    first,last=nz[0],nz[-1]; peak=max(abs(v) for v in seg)
    return f'sound {first/44100:.3f}s to {last/44100:.3f}s after start, peak {peak}'
for env in ['sim','cr']:
    L=load(f'{env}_capture.raw'); ev=events(f'{env}_log.txt')
    print('==', 'Simulator' if env=='sim' else 'emulator')
    for name,span in [('synth ADSR start',20000),('sampleplayer start',30000),('synth with callback start',15000),('delay start',40000),('bitcrusher start',20000),('fileplayer start',30000)]:
        a=ev[name][0]; print(f'  {name:26s}', describe(L,a,span))
    for cb in ['sampleplayer finished','synth finished']:
        if cb in ev: print(f'  {cb:26s} callbacks at', [f - ev["sampleplayer start" if "sample" in cb else "synth with callback start"][0] for f in ev[cb]][:1], 'frames after its start')
    a=ev['delay start'][0]; seg=L[a:a+40000]
    print('  delay segment peaks per 0.05 s:', [max(abs(v) for v in seg[i:i+2205])//100 for i in range(0, 40000-2205, 2205)][:14])
    a=ev['bitcrusher start'][0]; seg=[v for v in L[a+2000:a+12000] if v]
    vals=sorted(set(seg)); diffs=collections.Counter(q-p for p,q in zip(vals,vals[1:]))
    print('  bitcrusher distinct levels', len(vals), 'common step', diffs.most_common(1))
