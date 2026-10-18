# audio11

An LFO on a two-pole filter's frequency, probed with impulses every 0.25 s.

Language: C. Build: `make` (with PLAYDATE_SDK_PATH set).

Notes:

- Analysis helpers: `modfreq.py` (Python 3; it reads the capture or log files the probe writes, given as arguments or by the names in the script).
- The LFO depth is `DEPTH`, 0.01 by default (the filter frequency swings by plus or minus 220 Hz around 1000 Hz); another depth needs `#define DEPTH` changed in `src/main.c` (`make UDEFS=-DDEPTH=...` reaches only the device build, not the Simulator library).
- The probe writes `capture.raw` (16-bit mono) at frame 100; `modfreq.py <capture.raw>` prints the filter frequency implied by each impulse response.
