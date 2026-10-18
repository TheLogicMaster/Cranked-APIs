# audio14w

MIDI playback with a one-voice and a two-voice instrument (voice allocation for a chord).

Language: C. Build: `make` (with PLAYDATE_SDK_PATH set).

Notes:

- The same MIDI files and instruments as audio14, with two differences: the capture keeps the full 32-bit samples (audio14 keeps 16 bits), and the second playback (two voices) starts at frame 110, after the first has ended, where audio14 starts it at frame 75, while the first is still playing. The capture is written at frame 210.
- `poly.py <capture.raw>` (Python 3) reads this 32-bit capture and prints the level of each note (C4, E4, G4, C5) in parts of both playbacks.
