# Synthesizers, envelopes, LFOs and instruments

This file covers `playdate.sound.synth` and the C `sound->synth` API: the waveform generators (sine, square,
sawtooth, triangle, noise, the three Teenage Engineering generators, sample-based and wavetable synths), how a synth
renders a note inside the 256-sample block grid, envelopes (curvature, velocity sensitivity, legato, retrigger),
LFOs (built-in shapes, function LFOs, delay, ramp, arpeggios), other signals used as synth modulators, and
instruments with their voice choice. Behaviour is stated as it is on the device (3.1.2, by analysis); where a probe is
cited, the Simulator (SDK 3.1.1) was measured against it and matches unless a difference is noted. Block rendering,
channels, effects and the audio clock are in [effects.md](effects.md); sample data and players in
[players.md](players.md); sequences, tracks and MIDI files in [sequences.md](sequences.md).

Audio runs at 44,100 Hz. All "exact" statements below mean that a capture of the mix (see "How audio was measured"
in [effects.md](effects.md)) matches the Simulator on every sample.

## Creating synths

- **Default waveform:** a new synth plays a **triangle** wave. It reports 0 parameters (a square wave reports 1), so
  checking the parameter count does not tell triangle from sine, sawtooth or noise. A common mistake is to default to
  square or noise.
- **Default envelope:** no attack, no decay, full sustain, and a **5 ms release**. 5 ms is also the shortest release
  `setReleaseTime` gives.
- **`synth.new(waveform)`** (Lua) behaves exactly like `setWaveform` on a new synth: a square wave made this way has
  its default duty cycle (0.5).
- **`synth.new(sample, sustainStart, sustainEnd)`** makes a sample-based synth (see "Sample-based synths").
- **`synth:copy()`** returns a new synth with the same settings.
- **`getEnvelope`** returns the synth's own envelope. After `clearEnvelope`, `getEnvelope` still returns an envelope,
  with default settings.
- **Lua return values:** `playNote` and `playMIDINote` return `true`; `isPlaying` returns a boolean, not 0 or 1.

## Playing notes

### Pitch, `when`, and note-off

- **Pitch:** `synth:playNote` takes a frequency or a note name such as "C4". `playMIDINote` plays the note's
  frequency, 440 * 2^((note - 69) / 12) Hz. A frequency of 0 is a note-off.
- **Phase step:** the generator advances a 32-bit phase by trunc(frequency / 44100 * 2^32 * 2^(transpose / 12)) per
  sample.
- **`when`:** a note starts at that audio time. In Lua `when` is in seconds of audio time and becomes
  trunc(44100 * when) samples, in single precision. Without `when` (or 0) the note starts at once, which in practice
  means in the next rendered block.
- **`noteOff(when)`:** ends the note at that time and its release follows. **Lua truncates `when` to whole seconds
  before converting** (1.7 means 1.0). Without `when` the note is released now.
- **Lengths** are in seconds in Lua (0.3 means 0.3 s, not 0).
- **`isPlaying`** is true from `playNote` on, through the release.
- **`setFinishCallback`:** the Lua callback runs on the main thread, before the next `playdate.update`, after the
  synth has finished (the Simulator delivers it within one or two audio blocks of the sound ending, at the next
  update).

### The note queue

A synth has two note slots: its current note and one queued note.

- **Scheduling:** a note for later goes into the current slot if that is free, otherwise into the queue, replacing
  whatever was queued. So scheduling three notes ahead on one synth plays the first and the third.
- **A note for now** starts at once and clears the queue.
- **When the queued note comes due** (its start at or before the block's end), the playing note renders one segment
  only. The synth then skips to the queued note's start, silent in between, and starts it there. The old note gets
  no note-off, so the velocity-sensitivity retrigger (see "Velocity sensitivity") does not happen for it.
- **`noteOff` with no current note** moves the queued note up.
- **Phase:** while a note is queued the synth never counts as idle, so the next note keeps the oscillator phase.
- **One note-off per call:** a synth sends at most one note-off per `playNote` call, so when two notes are queued at
  once and the first one's length ends, the second gets no note-off of its own and simply releases at its length.

Covered by `tests/probes/audlfo2` and `tests/probes/audenv3` (a note during the previous note's sustain, during its
release and its retriggered release; with and without retrigger and velocity sensitivity; three chained notes; a
note-off between two held notes; all exact).

### State across notes

- The oscillator phase continues from note to note. It resets to 0 only when the synth was silent.
- The noise register starts at 1 for each synth and is never reset by notes.
- `setWaveform` resets the phase, the noise register and the square's duty cycle.

## Rendering a note inside the block grid

The engine renders in blocks of 256 samples on a fixed grid (see [effects.md](effects.md)). Each synth splits its
block into **segments** at:
- the note's start;
- the end of its length;
- envelope breakpoints (attack end, decay end, release start, release end);
- events of its LFO modulators (see "LFOs").

Breakpoints closer than about 1 ms to a segment's start are not split at.

Over each segment the amplitude ramps **linearly** from the previous segment's value to the envelope's value at the
segment's end. The amplitude is held in 4.28 fixed point, clamped at 7, and the ramp step is (a1 - a0) / segment
length, truncated. This is why every note seems to fade in over up to 256 samples: with no attack, the first segment
runs from the note's start to the block's end, and the amplitude ramps from 0 across it.

Generators produce 24-bit values (16-bit scale times 256). Each sample is multiplied by the amplitude and added to
the channel's signed 8.24 buffer:

    out = ((((v * a) >> 32) + (out >> 4)) << 4)        v: 24-bit value, a: 4.28 amplitude

The note's remaining length is computed once per block, as trunc(44100 * length) - samples played so far; a negative
value releases the note. The first segment ends at that offset if it falls inside the block.

**End of a note:** the envelope has its own clock, which advances by whole blocks (256 / 44100 s) from the note's
first block. A note stops at the end of the first block at which that clock is past the release's end. Depending on
where the note started in its block, this can cut the release short by up to a block.

## Waveforms

Every generator keeps a 32-bit phase p and a phase step s.

| Waveform | Phase step below 2^23 (under 86.13 Hz) | Phase step 2^23 and up |
| --- | --- | --- |
| Sine | 1,024-entry table, round(32767 sin(2 pi n / 1024)), linearly interpolated | same |
| Sawtooth | drawn directly: v = p >> 8 as unsigned, a **rising ramp from 0 to twice full scale** (a DC offset) | a **falling** band-limited ramp from a table |
| Triangle | drawn directly as straight lines | band-limited table (odd harmonics) |
| Square | -full scale for p < duty, then 0x7FFFFF (one step under +full scale) | two sawtooth table reads half a duty apart, subtracted |
| Noise | 16-bit LFSR, see below | same |

### Band-limited tables

Above a phase step of 2^23 the sawtooth, triangle and square read 256-entry tables, one per octave. Level k (0 to 5)
serves phase steps from 2^(23 + k) up, k = min(6, bitlength(s) - 24), and level 6 is a pure sine (the sine table).
The six table levels hold 85, 42, 21, 10, 5 and 2 harmonics, that is harmonics up to 256 / (3 * 2^k).

The tables are harmonic sums, each scaled so that its largest value is 32767 and then truncated:
- sawtooth: every harmonic h at amplitude 1/h;
- triangle: the odd harmonics at alternating sign, amplitude 1/h^2.

Summing from the highest harmonic down, in that formula, reproduces the tables except for nine entries that differ
by one step. These values are measured from the Simulator's output (SDK 3.1.1); `tests/probes/audtab` reads every
table back from an audio capture. Level k is counted from the lowest note range:

| Table | Entries that differ from the formula |
| --- | --- |
| sawtooth level 0 | [2] = 32767 |
| sawtooth level 1 | [3] = 32767 |
| sawtooth level 2 | [6] = 32767, [45] = 18647, [211] = -18647 |
| sawtooth level 5 | [43] = 32766, [213] = -32766 |
| triangle level 4 | [64] = 32766, [192] = -32766 |

Without them the error is one step at 9 of 3,072 entries (about -90 dBFS peak), inaudible, but bit-exact
comparisons of sawtooth and triangle notes in those ranges fail.

**Reading a table** of 2^b entries at phase p (16-bit linear interpolation):

    u = p >> (16 - b); i = u >> 16; f = u & 0xFFFF
    value = (f * T[i + 1] + (65536 - f) * T[i]) >> 8

**Triangle below 2^23:** with u = p >> 16, v = (u < 0x4000 ? 2u : u < 0xC000 ? 0x7FFF - 2(u - 0x4000) :
2(u - 0x10000)) << 8.

**Square above 2^23:** the generator adds +a * read(saw, p + duty) and then -a * read(saw, p). Because it is the
difference of two band-limited ramps, its edges overshoot: 17,051 at 440 Hz and volume 0.5, and up to twice full
scale at the top octave.

### Square duty cycle

`setParameter(1, width)` (or a parameter modulator) sets the duty, stored as a 0.32 fixed-point phase; the default is
0x80000000 (0.5).
- On the device (3.1.2, by analysis) the float-to-integer conversion saturates, so any value of 0.5 or more is stored as
  0x7FFFFFFF.
- In the Simulator (x86) it overflows to 0x80000000. A few samples in ten thousand differ by the last bit between the
  two.

### Noise

A 16-bit Fibonacci LFSR (taps 16, 14, 13, 11), output as a signed 16-bit value:

    if the noise phase, advanced by 16 * s per sample, wraps:
        x = ((((x >> 3) ^ (x >> 2) ^ x ^ (x >> 5)) & 1) << 15) | (x >> 1)
    v = (int16) x << 8                                   (x starts at 1)

So noise changes value every 1/16 of the note's period: it is pitched, not white, which explains its "crackly"
sound. Because the register is never reset, a second note on the same synth continues the sequence.

## Teenage Engineering generators

`kWaveformPOPhase`, `kWaveformPODigital` and `kWaveformPOVosim` are generators of their own, each with two
parameters. The parameters are stored as bytes (value * 255, truncated and clamped).

- **POPhase:** two sines read at (p1 + 32) / 32 and (p2 + 64) / 64 times the phase, summed and faded over each cycle,
  then scaled by p2 / 8 + 1 and saturated. Both parameters are latched when the phase wraps. POPhase synths playing
  at once affect each other's latching (on the device (3.1.2, by analysis); `tests/probes/audte` shows it in the
  Simulator too).
- **PODigital:** a sine with feedback (amount p2 squared), plus half a sine at a multiple of the frequency, XORed
  with the magnitude of a third sine (level p1 squared).
- **POVosim:** two raised-cosine pulse trains whose rates rise with p1 and p2. Each halves in level every quarter of
  its run, both restart each cycle, and the sum fades over the cycle's last quarter.
- **Note start:** every note-on sets both parameters back to 0.5 and restarts the phases. So a `setParameter` made
  before `playNote` has no effect; only a parameter modulator, applied each block, changes them.
- **Tables:** they use a 1,024-step sine (rounded, with one guard entry) and a raised cosine (rounded on the first
  half, mirrored for the second). Both can be generated; the generated tables reproduce the output exactly.

`tests/probes/audte` (defaults, parameters set before the note, parameter LFOs, frequency LFOs, two phase synths at
once): 11 of 11 cases exact.

## Sample-based synths

`setSample(synth, sample, sustainStart, sustainEnd)` (Lua `synth.new(sample, sustainStart, sustainEnd)`):
- **Pitch:** the sample's own pitch is middle C at the documented 261.63 Hz (not the equal-tempered 261.6256). The
  playback step is the 16.16 value round(phaseStep * 65536 / (261.63 * (2^32 - 1) / sampleRate)), with the divisor in
  single precision (measured: 22 of 22 notes chosen around middle C, `tests/probes/midc`).
- **Sustain loop:** while the note is held, playback loops from the sustain end back to the sustain start, exactly at
  the start (the step's overshoot is dropped, the fraction kept). A sustain end of 0 means the sample's end when a
  start is given, and no loop otherwise; a larger end is clamped.
- **Release:** stops the looping, and the rest of the sample plays out. With the default envelope (no real release)
  the level does not fall at the note's end, so the note lasts until the sample runs out. A sample that runs out ends
  the note.
- **Rendering:** the same interpolation as the sample player, including its stereo quirk (see
  [players.md](players.md)), with the synth's volume ramps. At unity volume with no ramp the value is added as is.
- On the device (3.1.2, by analysis), games built with older SDKs get a different limit on sample-synth pitch; it
  does not apply to SDK 3.1.1 games.

`tests/probes/audsamp` (no loop, loops at three pitches, stereo, 8-bit, unity volume, an ADSR, an end past the
sample): 9 of 9 exact.

## Wavetable synths

`setWavetable(synth, sample, log2size, columns, rows)`:
- **Setup:** the sample must be 16-bit mono and hold columns * rows tables of 2^log2size samples each. Otherwise it
  fails with "wavetable source must be 16 bit mono" or "wavetable requires %i x %i x %i = %i samples, only %i in
  sample" (the numbers filled in). Lua also checks that the table size is a power of two ("wavetable size must be a
  power of two").
- **Parameters:** 1 sets the X position in cells (0 to columns - 1), 2 sets it from 0 to 1. Parameters 3 and 4 do the
  same for Y, and only when there are two rows or more. Values are clamped to the grid.
- **Rendering:** each render call (each segment) moves the current position toward the target, crossing at most one
  cell boundary. The output mixes the two (or, with rows, four) neighbouring tables, with weights that ramp from the
  start position's fractions to the end position's, on the synth's phase. A new note starts at the target.

Because the position moves at most one cell per segment, where segments split (for example at a parameter LFO's
events) changes the output. `tests/probes/audwtab` (8 cases) and `tests/probes/audwtab2` (4 modulated cases) are exact.

## Envelopes

### Shape

Linear attack, decay and release, with values that **include the note's level** L (from the velocity):

    t >= release start:  t - start >= R ? done (0) : last + (0 - last) * (t - start) / R
    t >= A:              t - A >= D ? L * S : L + (L * S - L) * (t - A) / D     (this value is remembered as last)
    else:                startLevel + (L - startLevel) * t / A

R is at least 0.005 s. Computing a 0-to-1 envelope and multiplying by the level afterwards rounds differently and is
one output step off on a few dozen samples per note; a common mistake.

The envelope is evaluated two ways: the per-block step evaluates it at the envelope's own clock, and segments
evaluate it at the note's clock.

### Curvature

`setCurvature(amount)` (Lua `envelope:setCurvature`, and `synth:setEnvelopeCurvature(amount)` for the synth's own
envelope): the amount is clamped to 0..1. Every stage (attack, decay, release) passes its 0-to-1 fraction through a
16-point curve, 1 - (2^(k i / 16) - 2^k i / 16) with k = -8 * amount, linearly interpolated between its points.
`tests/probes/audenv2` covers curvature 0.2, 0.5, 0.7 and 1.0 (exact).

### Velocity sensitivity

With sensitivity s (default 1) and f(x) = 1 - s + s x, the note's level is **f(f(velocity))**: the note-on applies f,
then the envelope's trigger applies it again. So s = 0 plays every note at full level, and s = 0.5 with velocity 0.4
plays at 0.85.

**Note-off:** the note-off triggers the envelope again with velocity 0. The synth calls it where the note's length
ends (at that sample offset), or at the start of the next block if the end has already passed.
- With s = 1 the level is 0, and this is a plain release.
- With s below 1 the level is 1 - s, so the envelope restarts:
  - it starts from its current value (from 0 when retrigger is set) and heads toward 1 - s;
  - its release start becomes its clock at the block's start plus the note-off's offset;
  - its own clock restarts at 0, but the synth evaluates it on the note's clock, which keeps running.

  So the release in progress goes on, but at each block the value it releases from is taken from the restarted
  attack and decay. With s = 0 the note swells back toward full level as it fades.

`tests/probes/audenv2` covers sensitivity 0, 0.3 and 0.5 through the note-off and release (exact).

### Note start, retrigger and legato

- **Start level:** a note that starts while the envelope still runs (sustain or release) attacks from the envelope's
  value at its last block step, not from 0, unless the envelope's retrigger flag is set.
- **Legato** (`setLegato(true)`): a note that starts while the envelope runs and has not reached its release does not
  trigger the envelope. Instead:
  - only the level changes, to f(velocity) applied once;
  - a release start, if set, moves to the envelope's clock plus the new length;
  - the envelope's clock and start level stay.

  The synth's note clock restarts, though, so the attack is evaluated again from the old start level (0 for a first
  note): each legato note dips and swells. A note during the release triggers as usual.
  `tests/probes/audenv4` (the audenv3 cases with legato on) is exact.

In summary, at a note start:

    legato, envelope running and before its release:
        L = f(velocity); release start (if any) = envelope clock + length; envelope clock and start level stay
    otherwise:
        L = f(f(velocity))
        startLevel = (envelope running and not retrigger) ? value at the last block step : 0
        envelope clock = 0; release start = the note's length (none without a length)

### Rate scaling

`setRateScaling` is not modelled here: it has no effect on ordinary notes (at most on legato notes), and the measured
cases match without it.

### Envelopes as modulators, and on their own

An envelope can be a synth's frequency, amplitude or parameter modulator.
- **State lives in the envelope:** its clock, level, start level and release time. A shared envelope steps once per
  block, however many users it has.
- **Value:** offset + scale * the envelope's value at that step (scale defaults to 1). The value is held for the whole
  block, with no interpolation and no mid-block events.
- **Notes:** the synth's note-on and note-off reach it with the note's velocity and length, with the same rules as the
  synth's own envelope (f(f(velocity)), start from the current value, legato, the note-off retrigger).
- **Use:** as a frequency modulator, octaves added to the transpose, one step per block; as an amplitude modulator, a
  factor clamped at 0; as a parameter modulator, passed to the generator's `setParameter`.
- **`getValue`:** the value at the last step (for a synth's own envelope, the value the synth stepped it to).
- **Lua `envelope:trigger(velocity, [length])`:** triggers it directly with f(velocity). The length is -1 when
  omitted, and 0 when given as nil.
- **`envelope:setGlobal(true)`:** adds the envelope to the signals stepped every audio block, so it runs without a
  user; an unused, non-global envelope stays at 0. (In the Simulator, a global envelope that is also a synth's
  modulator crashes the Simulator; the device is likely affected too (**check on hardware**). Global envelopes on their
  own work.)

`tests/probes/audenv5` (frequency, amplitude, shared and square-duty modulators; sensitivity 0, 0.3, 0.5; retrigger,
curvature, legato) and `tests/probes/luaenvg` are exact.

## LFOs

### State and stepping

- An LFO's state belongs to the LFO. Used by two synths, or set global, it still advances **once per audio block**.
  Global LFOs advance every block, used or not.
- **Phase:** 16 bits, advanced each block by trunc(256 * trunc(rate * 65536) / 44100).
- **Value:** center + depth * shape(phase), taken at the block's end. On the device (3.1.2, by analysis) it is rounded
  once (fused multiply-add); the Simulator multiplies and adds separately, which can differ in the last bit of the float
  (through a square wave's duty cycle that changes a few samples).
- **Defaults:** depth 1, rate 1 Hz, center 0.
- `lfo:setOffset` and `lfo:setScale` exist and are the same as `setCenter` and `setDepth`.

### Shapes

| Shape | Value over a cycle | Events per cycle |
| --- | --- | --- |
| Square | +1, then -1 (starts high) | 2 (each edge) |
| Triangle | from -1 up to +1 at half phase, then down | 2 (each turn) |
| Sine | a 17-entry quarter-wave table, entry i = trunc(32767.5 sin(i pi / 32)), interpolated with 10-bit fractions; starts at 0, rising (measured at every phase, `tests/probes/sinetab`) | none |
| Sawtooth up | -1 to +1 | 1 (the wrap) |
| Sawtooth down | +1 to -1 | 1 (the wrap) |
| Sample and hold | a 16-bit LFSR value, the register starting at 0xDAFE (measured: the Simulator's first value is one step after it, `tests/probes/sinetab`); one value per period | 1 (each new value) |

The sine table's values match neither rounding nor truncation of 32767 sin x; the formula above reproduces them
(measured in the Simulator). The same table drives the ring modulator (see [effects.md](effects.md)).

### Events and segments

Each event (square edge, triangle turn, sawtooth wrap, new random value) is scheduled by a countdown from the phase at
the previous event's block:

    per block: if the countdown e < 256:
                   step the LFSR (sample and hold)
                   e = 256 + 44100 * ((65536 - (k * phase mod 65536)) / k) / trunc(rate * 65536)
                   v2 = the value just before the next event
               else e -= 256

The synth splits its segment at the event. It holds the value just before the event up to it, then uses the block's
end value. A sample-and-hold value changes at the start of the block after its event.

- **Frequency modulation:** the value is in **octaves**: frequency * 2^value. A square LFO at depth 0.5 swings exactly
  plus or minus 6 semitones, at depth 1 a full octave. Triangle, sine and sawtooth sweep the phase step linearly from
  the previous segment's value (kept across notes; 0 for a new synth) to the segment's end value. Square and sample
  and hold stay constant within a segment.
- **Amplitude modulation:** the envelope's value at each segment's end is multiplied by max(0, the LFO value).
- **Parameter modulation:** see "Parameter modulators".

### Note start, delay, ramp, retrigger

- **Each note** resets the LFO's event countdown and its delay clock. The phase continues, and returns to the start
  phase only when retrigger is set. A retriggered LFO restarts from the start of the block the note begins in, so a
  note that starts late in a block hears an LFO already up to 256 samples along.
- **Delay (holdoff):** during the delay the LFO gives its center, and its phase does not move. After it, the depth
  ramps in linearly over the ramp time.
- `setRate` and `setPhase` restart the event countdown; `setStartPhase` does not move the current phase.
- **`setRandomSeed`** exists in Lua.

### Arpeggios

`lfo:setArpeggio(...)` takes the steps as separate arguments. The steps are semitones, used as octaves (step / 12),
one step per 1 / (steps * rate) of a cycle.

### Function LFOs

`setFunction` makes the LFO call the game's function once per cycle, at the cycle's event, from the audio render. In
the block of that event the LFO's value is center + depth * the result; in every other block the value is the center
alone. The `interpolate` flag makes a frequency modulator sweep between blocks, as for the smooth built-in shapes.
`tests/probes/audlfofn` (frequency and duty modulators, with and without interpolation) matches, with the same number
of calls.

Covered by `tests/probes/audlfo2` (running phase, retrigger with a start phase, delay and ramp, arpeggio, shared LFO;
5 of 7 cases exact, the global LFO case depends on when the game scheduled the note, and one amplitude LFO with a
delay differs in one release tail) and `tests/probes/luacap4` (Lua arpeggio, delay, sample-and-hold, retrigger).

## Parameter modulators

At the start of each block every parameter modulator is stepped and its value is passed to the generator's
`setParameter`. A modulator's event (a triangle's turn, for example) also ends the current render segment, as the
frequency and amplitude modulators' events do. Valid indices are 0 to 4 (a common bug is writing index 4 past a
four-entry array).

Control signals and the channel level signals can also be used wherever a modulator is accepted (see
[sequences.md](sequences.md) and [effects.md](effects.md)).

## Instruments

### Voices

- **`instrument:addVoice(synth, [rangeStart], [rangeEnd], [transpose])`** adds the synth as a voice. Notes may be
  numbers or names ("C4"). The C `addVoice` is the same.
- **`instrument.new(synth)`** starts with that synth as a voice.
- **Errors:** adding a synth that is already a voice (of any instrument), or that has played notes on its own, raises
  "synths may only be in one instrument or channel at a time" (`tests/probes/voiceq`). A synth that is only in a
  channel is fine; added as a voice it leaves its channel. `instrument.new` with something that is not a synth is an
  argument error.
- **`activeVoiceCount`** counts voices holding a note.

### Playing

- **`playNote(frequency or name, [vel], [length], [when])`:** converts a frequency to a MIDI note number first. It
  does nothing at velocity 0, and honours `when` (seconds in Lua). C returns the voice's synth; Lua returns true.
- **`playMIDINote`** likewise.
- **`noteOff`**, **`allNotesOff([when])`:** Lua's `allNotesOff` takes seconds but truncates them to whole seconds
  before multiplying by 44100; without `when` it is now. `instrument:stop()` is the same function as `allNotesOff`.
- **`instrument:isPlaying()`** exists.
- **Volume:** each voice's volume is scaled by the instrument's volume for the block.

### Voice choice

For a new note (from `playNote` or a sequence):
1. the first voice in range holding no note;
2. otherwise the voice released longest ago;
3. otherwise the voice whose note started longest ago, before the current block (it is stolen, continuing its phase);
4. otherwise the note is dropped.

A voice holds its note until its synth has finished, release included. So a one-voice instrument plays only the
first note of a chord. Keep voices in an ordered list; a choice that depends on container order or memory addresses
will not match.

### Rendering and channels

An instrument is a single source: it renders its voices that hold a note, in the instrument's channel and through
that channel's effects (a voice is not a separate source in the default channel). `playdate.sound.playingSources()`
counts an instrument as one source.

- **C:** an instrument is silent until it is added to a channel.
- **Lua:** an instrument made in Lua plays on the default channel without being added (measured: a MIDI sequence
  through such an instrument is audible at full level for its whole length).

### Pitch bend

An instrument's pitch bend range is 12 half steps when made. `track:setInstrument` sets it to the track's range,
which is 0 unless the MIDI file set it with RPN 0, so a file without RPN 0 plays its bends flat. When the bend
changes, every voice's transpose becomes bend * range. See [sequences.md](sequences.md) for how a track's pitch bend
signal is read.
