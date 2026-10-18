# Sequences, tracks, control signals and MIDI files

This file covers `playdate.sound.sequence`, `playdate.sound.track` and `playdate.sound.controlsignal` (and their C
counterparts `sound->sequence`, `sound->track` and `sound->controlsignal`): storing notes and tracks, tempo and steps,
playback timing to the sample, loops, seeking and the current step, stop and finish callbacks, control signals as
modulators, and loading Standard MIDI Files. Behaviour is stated as it is on the device (3.1.2, by analysis); where a
probe is cited, the Simulator (SDK 3.1.1) was measured against it and matches unless a difference is noted. The synths
and instruments a track plays through, voice choice and pitch bend ranges are in [synth.md](synth.md); the block grid
in [effects.md](effects.md).

## Steps, tempo and indices

- A sequence's **tempo** is in steps per second. A new sequence reports a tempo of 16. Lua has `getTempo`.
- **Lua is 1-based, C 0-based:** `track:addNote` steps, `sequence:getTrackAtIndex`, `goToStep` and the current step,
  and control signal events. `getTrackAtIndex` returns the same Lua value each call.
- A step s starts trunc(s * 44100 / tempo) samples into the pass, in single precision (not ceil, and not double
  precision: either is one sample late where the value rounds up).

## Tracks

- **Notes:** `addNote`, `setNotes`, `getNotes`, `removeNote` and `clearNotes`. `getNotes(step, endStep)` returns the
  notes in that range; with no arguments, every note. Notes may be MIDI numbers or names ("C4").
- **Length:** a track's length is the end of its last note.
- **`getIndexForStep(step)`** returns the first note at or after the step.
- **`getPolyphony()`** is the most notes open at once (for a MIDI track, counted while reading the file; see below).
- **`getNotesActive()`** counts the notes sounding now.
- **Instrument:** `setInstrument` takes an instrument, or a synth, which then gets an instrument of its own (as
  documented). `setInstrument` also sets the instrument's pitch bend range to the track's (see "Pitch bend").
- **Control signals:** a track keeps its control signals (`getControlSignals`).

## Sequences

- **`addTrack`:** Lua takes a track and returns nothing; C creates and returns a track.
- **`setTrackAtIndex`** past the end grows the list.
- **`getLength`** is the end of the last note over all tracks.
- **`play`, `stop`, `isPlaying`** and the current step work as described below; `isPlaying` returns a boolean.

### Playback timing

- **Note start:** a note at step s starts at trunc(s * 44100 / tempo) samples into the pass, on its exact sample.
- **Note length:** length / tempo seconds, then the instrument's release.
- **Pitch and level:** the instrument's voice plays at 440 * 2^((note + transposes - 69) / 12) Hz; the velocity is
  the volume (1.0 full scale, 0.5 half).
- Notes are given to the track's instrument, which picks a voice (see "Voice choice" in [synth.md](synth.md)).
- A sequence started from Lua begins within a few samples of `play` (the next block).

### Loops

`setLoops(start, end, [loops])`:
- The loop covers steps start to end **inclusive** (0 to 8 repeats every 9 steps).
- `loops` is the total number of passes through the loop region; 0 loops forever.
- Playback begins at step 0, not at the loop start.
- **The loop jump:** playback continues to one sample before the end step's first sample, that is, to the start of
  step end + 1. The pass then restarts at the loop start **plus the rest of the block**, as if that were the block's
  start. So every looped pass sounds about one block (256 samples) early, and its first notes start at the
  beginning of the block in which the jump happens.

In a block that starts at pass time t:

    used = start(end + 1) - t - 1          samples play normally
    t = start(loopStart) + (256 - used)
    notes from loopStart up to t + (256 - used) play in this block at offset max(0, noteStart - t)

### Position, seeking and the current step

The play position is a sample count from step 0.
- **`goToStep(step, [play])`** (Lua, 1-based; a step of 0 or below is used as given) and C **`setCurrentStep(step,
  offset, playNotes)`** set it to trunc(44100 * step / tempo) + offset, in single precision. With play set, the notes
  that start at exactly that step play at once.
- **`getCurrentStep`** is trunc(((position + 1) * tempo - 1) / 44100), plus 1 in Lua; C's offset output is the rest.
  A sequence started from the beginning reports step 1 in Lua.
- **C `setTime` and `getTime`** set and read the position itself.
- Seeking also sets the position of the tracks' control signals (see below).

The Lua cases above are confirmed in the Simulator by `tests/probes/seqpos`.

### Play, stop, and the finish callback

- **`play([finishCallback])`** resumes from the position. While already playing it does nothing (the callback is not
  replaced).
- **`stop`** keeps the position (it is a pause) and runs the finish callback at once (Lua: before `stop` returns).
- **The end:** the finish callback runs, and the position returns to 0.
- **Lua finish callbacks** get the sequence. They run on the main thread, at the next game update after the end, with
  `isPlaying()` already false (measured: 769 samples after the last sound, at the next update).
- **C finish callbacks** get the sequence and the userdata.

### `allNotesOff`

Each track's instrument turns its voices' notes off at the current time.
- A note played without a length (for example `playMIDINote(inst, note, vel, -1)`) is released.
- Notes the sequence started keep sounding to their full length (`tests/probes/audseqoff3`).
- Called from inside the audio render (an effect callback), it changes nothing (`tests/probes/audseqoff`).

## Control signals

- **`controlsignal.new()`**; a signal not tied to a MIDI controller reports controller number 255. Lua signals keep
  an `events` table and a controller number.
- **Events:** one event per step; adding at an existing step replaces it. Lua steps are 1-based (a common mistake is
  to store the 1-based step as given, one step late). An event can be marked to interpolate.
- **Position:** a control signal on a track has a position, which the sequence sets when it plays, seeks or jumps at a
  loop. It is a sample count at the sequence's tempo.
- **Stepping:** each block the signal is stepped once, however many users it has, to the step at the block's end.
  - Its value is the last event at or before that step; before its first event it is 0.
  - After an event marked interpolate, the value moves each block toward the next event's value by
    (target - value) * block / samples left.
- **Value:** offset + scale * that, as for every signal; `setOffset` and `setScale` exist.
- **`getValue`:** the value at the last step, also through the generic signal `getValue`.
- **As a modulator** it gives one value per block, with no mid-block events.

`tests/probes/audcs` (4 cases) is exact on every sample.

## MIDI files

`sequence.new(path)` (Lua) and `sequence->loadMIDIFile` (C) load a Standard MIDI File.

### Structure

- **Steps** are MIDI ticks, one for one (1-based in Lua).
- **Format 0:** 16 tracks, one per MIDI channel (channel 10's notes go to track 10 in Lua).
- **Format 1:** one track per MTrk chunk, with all its channels together. So a file with a conductor track and two
  parts has 3 tracks, the first empty. The load fails past the header's track count.
- **Other formats** load no notes.
- The load fails into a sequence that already has tracks.
- **Event lengths:** meta and system event lengths are read as one byte. A delta time longer than 5 bytes, or a read
  past the end, fails the load.
- Program changes are ignored. Files with SMPTE timing were not measured.

### Tempo

tempo = (60000000 / microseconds per quarter) * division / 60, in single precision: ticks per second, 192 for 96
ticks per quarter at 120 bpm. With no tempo event the default is 120 bpm (0.5 s per quarter). **Only tempo events at
tick 0 count**: later tempo changes are ignored and notes stay at their tick positions, so a file that slows from 120
to 60 bpm plays at 120 throughout. The Simulator (SDK 3.1.1) instead uses the first tempo event of the file wherever
it is (check on hardware).

### Notes

- A note-on adds a note of length 1.
- A note-off (or a note-on at velocity 0) sets the length of the track's latest note of that pitch, closed or not.
- A note-off with no note of that pitch adds a zero-length note with velocity 0.
- So of two overlapping notes of one pitch, the first keeps length 1, and a note never released has length 1.
- **Velocity** is MIDI velocity / 127.
- **Polyphony** (`getPolyphony`) is the most notes open at once while reading. Every note-off counts down, matched or
  not.

### Controllers and pitch bend

- Controllers other than the RPN ones go to the track's control signal for that controller (`getControlSignals`).
- **RPN 0** (CC 101 and 100 at 0, then CC 6 for half steps and CC 38 for cents) sets the track's pitch bend range.
- **Pitch bend** goes to the track's pitch bend signal, as (value - 8192) / 8192.

### Pitch bend at playback

- An instrument's pitch bend range is 12 half steps when made. `track:setInstrument` sets it to the track's range,
  which is 0 unless the file set RPN 0. **So a file without RPN 0 plays its bends flat.**
- Each block, the track's pitch bend signal is read at the step at the block's end. When it changes, the instrument
  gets it: every voice's transpose becomes bend * range.

`tests/probes/midi3` (format 1) matches the Simulator line for line; `tests/probes/audmidi` matches on every sample
with an RPN range, without RPN, and with a range set after `setInstrument`; `tests/probes/midi` covers format 0 files.
