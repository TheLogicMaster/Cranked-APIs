# luacap4

Lua LFO API (arpeggio, delay, retrigger, random seed), notes on the audio clock, captured through a C capture effect.

Language: C + Lua. Build: `make` (with PLAYDATE_SDK_PATH set).

Notes:

- The probe writes `capture.raw` (the left channel its capture effect saw, 16-bit mono) to its data folder. No expected output is included: the capture is not kept, and there is no helper for it.
