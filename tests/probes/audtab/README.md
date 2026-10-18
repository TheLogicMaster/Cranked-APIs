# audtab

Synth notes whose phase steps land on exact wavetable entries; rec.py reads the sampled waveform back from a capture.

Language: C. Build: `make` (with PLAYDATE_SDK_PATH set).

Notes:

- `rec.py <capture.raw> [onset offset]` reads the sampled waveform back from a capture and writes it to tables.json (it loads the capture with `seg.py`, in the same folder).
