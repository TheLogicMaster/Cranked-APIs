import struct, sys
d=open(sys.argv[1],'rb').read(); n=len(d)//4; v=struct.unpack('<%dh'%(n*2), d[:n*4]); L=v[0::2]; R=v[1::2]
M=[max(abs(a),abs(b)) for a,b in zip(L,R)]
segs=[]; start=None; last=None
for i,x in enumerate(M):
    if x>100:
        if start is None: start=i
        last=i
    elif start is not None and i-last>3000: segs.append((start,last)); start=None
if start is not None: segs.append((start,last))
names=['pan -1','pan -0.5','pan 0','pan +0.5','pan +1','volume 0.5, pan 0']
print('segments', len(segs))
for k,(a,b) in enumerate(segs[:6]):
    pl=max(abs(x) for x in L[a+2000:b-2000]); pr=max(abs(x) for x in R[a+2000:b-2000])
    print(f'  {names[k]:20s} left peak {pl:6d}  right peak {pr:6d}  (left {pl/16384:.4f}, right {pr/16384:.4f} of the unpanned level)')
