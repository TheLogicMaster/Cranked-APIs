# Impulse responses from audio6's capture.raw: prints the first 30 samples of each of the eight cases src/main.c
# plays (a low-pass two-pole filter at 1 kHz with resonance 0, 0.25, 0.75 and 0.9, then a one-pole filter with
# parameter -0.9, -0.5, 0.2 and 0.9), and where each response's last nonzero sample is.
# Usage: ir.py <capture.raw>
import struct, sys
d=open(sys.argv[1],'rb').read(); n=len(d)//2; L=struct.unpack('<%dh'%n, d[:n*2])
# an event starts at the first nonzero sample after at least 500 zero samples
events=[]; quiet=500
for i,v in enumerate(L):
    if v==0: quiet+=1
    else:
        if quiet>=500: events.append(i)
        quiet=0
names=['two-pole low-pass 1 kHz res %g'%r for r in (0, 0.25, 0.75, 0.9)]+['one-pole parameter %g'%p for p in (-0.9, -0.5, 0.2, 0.9)]
for k,e in enumerate(events[:8]):
    end=events[k+1] if k+1<len(events) else n
    last=max(j for j in range(e,end) if L[j]!=0)-e
    print(names[k], 'first 30 samples:', list(L[e:e+30]), 'last nonzero at +%d'%last)
if len(events)!=8: print('expected 8 events, found', len(events))
