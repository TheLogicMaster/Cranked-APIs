# audsw

Synth waveforms at several frequencies (band limiting).

Language: C. Build: `make` (with PLAYDATE_SDK_PATH set).

Notes:

- `build.sh <SoundWaveform constant> <out.pdx>` builds the probe for one waveform; `simrun.sh <pdx> <out.raw>` records it in the Simulator; `an.py <capture.raw>` lists the harmonics per frequency.
