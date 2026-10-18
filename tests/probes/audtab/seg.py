import struct, sys
def load(p):
    d=open(p,'rb').read(); return list(struct.unpack('<%dh'%(len(d)//2), d))
def segs(L, thr=50, gap=2000):
    out=[]; start=None; last=None
    for i,x in enumerate(L):
        if abs(x)>thr:
            if start is None: start=i
            last=i
        elif start is not None and i-last>gap: out.append((start,last)); start=None
    if start is not None: out.append((start,last))
    return out
if __name__=='__main__':
    L=load(sys.argv[1]); s=segs(L)
    for a,b in s: print(a,b,b-a, max(L[a:b]), min(L[a:b]))
