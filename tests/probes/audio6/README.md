# audio6

Impulse responses of the effects with memory, captured after the effect.

Language: C. Build: `make` (with PLAYDATE_SDK_PATH set).

Notes:

- The probe plays an impulse through eight effects in turn, 20 frames apart: a two-pole low-pass filter at 1 kHz with resonance 0, 0.25, 0.75 and 0.9, then a one-pole filter with parameter -0.9, -0.5, 0.2 and 0.9. It writes `capture.raw` (16-bit mono, after the effect) to its data folder at frame 190.
- Analysis helpers (Python 3): `ir.py <capture.raw>` prints the start of each impulse response; `biquad.py <capture.raw>` fits biquad coefficients to the four low-pass responses and compares them with RBJ filters.
