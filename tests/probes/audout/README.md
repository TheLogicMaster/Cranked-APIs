# audout

The final output mix: default channel, pan and volume LFOs, volume and pan, loud notes at once.

Language: C. Build: `make` (with PLAYDATE_SDK_PATH set).

Notes:

- `simout.sh <pdx> <out.raw> [seconds]` records the Simulator's final mix through SDL's disk audio driver; `cmp.py` compares sim_out.raw with cr_out.raw (an emulator's final mix, for example from a runner that writes it to a file).
