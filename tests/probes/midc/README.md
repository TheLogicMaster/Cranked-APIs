# midc

Sample-based synth playback steps at chosen frequencies: how the step through a sample depends on the note frequency.

Language: C. Build: `make` (with PLAYDATE_SDK_PATH set).

Notes:

- The sample is a 44100 Hz sawtooth (60 ramps of 1000 frames, values -30000 to 29940), so each output value shows where in the sample playback is. Each note gets its own synth (setSample with no sustain loop), velocity 1, length 1.6 s; the notes start 0.1 s after frame 5, 1.5 s (66,150 frames) apart. The default channel's output goes through a capture effect that keeps the full 32-bit samples, and `capture.raw` (int32, little-endian, left channel) is written at frame 1055.
- `freqs.json` lists the note frequencies in the order they play, the same list as `freq[]` in `src/main.c`: 20 random frequencies between 207 and 285 Hz, then 261.6256 Hz (middle C) and 440 Hz.
- `expected/capture.raw` is the capture the Simulator wrote (552,960 bytes), included as a Simulator measurement.
