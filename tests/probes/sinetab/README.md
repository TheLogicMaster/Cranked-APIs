# sinetab

The sine table behind the ring modulator and the LFOs: the ring modulator at every phase, sine LFO values, and the sample-and-hold LFO sequence.

Language: C. Build: `make` (with PLAYDATE_SDK_PATH set).

Notes:

- The probe writes four files to its data folder at frame 260:
  - `capture.raw`: int32 little-endian, the left channel after a ring modulator at 44100 / 65536 Hz (a phase step of 1, so every 16-bit phase in turn) on a constant input of 2^30 (a custom effect before it sets every sample);
  - `lfo.bin`: 4096 float32 values, `getValue` of global sine LFOs (rate 0, depth 1, center 0) set to the phases 0 to 65535 in steps of 16;
  - `sh.bin`: float32 [4][240], `getValue` once per frame of four global sample-and-hold LFOs (depth 1, center 0): rate 5 Hz with the default seed, with seed 0, with seed 0x1234, and rate 7.5 Hz;
  - `done.txt`: "done" once the others are written.
- `expected/` holds the four files as the Simulator wrote them; the binary captures are included as Simulator measurements.
