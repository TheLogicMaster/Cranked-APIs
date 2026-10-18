# The mixer: channels, sources, effects and the audio clock

This file covers how the sound engine mixes: the 256-sample block grid and the order in which channels, sources and
effects render; channels (`playdate.sound.channel`, C `sound->channel`), source membership, channel sources and
custom C sources and effects; the built-in effects (two-pole and one-pole filters, bitcrusher, ring modulator,
overdrive, delay lines and taps) and their modulators; the channel volume and pan stage and the final mix; channel
level signals and the signal classes; the audio clock; and the small sound functions around them (microphone,
headphones, `getCurrentTime`). Behaviour is stated as it is on the device (3.1.2, by analysis); where a probe is cited,
the Simulator (SDK 3.1.1) was measured against it and matches unless a difference is noted. Generators are in
[synth.md](synth.md), players in [players.md](players.md), sequences in [sequences.md](sequences.md).

## How audio was measured

The behaviour here was captured from games, not by listening:
- **The mix before the channel stage:** a small C game adds a custom effect (`sound->effect->newEffect`) to the
  default channel and records the buffers its callback receives (the channel's mix in signed 8.24) to a file, while it
  plays the sounds under test (`tests/probes/audioc` and the `aud*` probes). The same probe can be run in the
  Simulator, in an emulator or on a Playdate.
- **The final output:** the Linux Simulator outputs through SDL. Run headless with `SDL_AUDIODRIVER=disk` (and
  `SDL_DISKAUDIOFILE=<path>`), it writes its final 16-bit stereo output to a file; without an audio device the
  Simulator never runs its audio engine at all (its audio clock stays at 0 and sounds never finish). It starts with its
  volume slider at zero, which has to be raised in its window first. Its output stream drops samples now and then once
  a run is several seconds in, so final-output probes (`tests/probes/audout`, `audout2`) keep their cases early and
  short.

## Blocks and rendering order

- **Blocks:** the engine renders 256 samples at a time, on a fixed grid of audio time. Each custom effect callback and
  each C source callback is called with one block.
- **Sample format:** sources mix into each channel's buffer in signed 8.24 fixed point; effects see that.
- **Order:** channels render in the order they were added, and a channel's sources in the order they were added, then
  the channel's effects in the order they were added. Keep all three in ordered lists; hash order or address order
  changes the mix.
- **Global effects** added with `playdate.sound.addEffect` run after the default channel's own effects (a capture
  effect on the default channel does not see them).
- **Signals** (LFOs, envelopes, control signals) are stepped once per block, however many users they have; global
  ones every block.

### When the device renders

On the device (3.1.2, by analysis):
- A block is rendered every 256 output frames, preempting the game at any point (in Lua, in C, mid-frame) except
  inside a sound API call (the render waits for that call to return).
- A render still running when the next one is due is not restarted; that block is an underrun and nothing piles up.
- C custom sources and effects, and C sample-player callbacks, run inside the render. Lua sound callbacks (finish,
  loop and fade callbacks) run later, on the main loop, before the next `playdate.update`.

So a `playNote` without `when` lands in the first block rendered after the call.

## The audio clock

- **`sound.getCurrentTime()`** (Lua) is seconds as a float; C `getCurrentTime` is in samples. `when` arguments are on
  this clock.
- **Simulator:** its audio starts about 7,168 samples before the first update, then advances in 1,024-sample SDL
  buffers (1,024 or 2,048 samples between updates). Its audio runs in real time, independently of the frame loop.
- On the device (3.1.2, by analysis): the clock advances one block per 256 output frames; its offset at the first update
  is not known.
- An emulator that renders blocks as each frame's time passes sees 1,280 or 1,536 samples between updates at 30 fps,
  so frame-timed audio events can land about a frame away from the Simulator's. Games that animate from
  `getCurrentTime` (rhythm games, title screens) follow the clock.

## Channels and sources

### Membership

- A source (synth, sample player, file player, instrument, delay line tap, channel source, callback source) belongs to
  **at most one channel**.
- A new source is in no channel until it plays, when it joins the default channel.
- Adding a source to a channel it is already in succeeds (returns true); adding it to a second channel fails.
- Removing a source leaves it in no channel until it plays again (then the default channel).
- A source rendered from two channels would advance its state (phase, envelope, position) twice per block; a common
  mistake is to put every new source in the default channel at once and keep it there when it is added elsewhere.
- C instruments are silent until added to a channel; Lua instruments play on the default channel (see
  [synth.md](synth.md)).
- What a missing (nil or NULL) source in `addSource` or `removeSource` does on the device is not known; check on
  hardware.

### Channels

- **`newChannel`** already puts the channel in the mix: a channel never passed to `addChannel` is heard,
  `addChannel` on it returns 0, and `removeChannel` returns 1 and silences it (`tests/probes/audchadd`).
- **Lua return values:** `channel:addEffect`, `channel:removeEffect` and `channel:removeSource` return nothing.
- **Lifetime in Lua:** a channel made with `playdate.sound.channel.new()` stays alive while it is in the mix, with
  the effects added to it, even when the game keeps no reference to either; after `channel:remove()` it is
  collected like any other value, and so is an effect that was never added to a channel (`tests/probes/gckeep`). The
  difference shows in weak tables, and in memory for games that make channels often.

### Channel sources

- **`channel->getOutputAsSource()`** (Lua `channel:getOutputAsSource()`, a `playdate.sound.channelsource`) makes one
  source per channel on the first call; later calls return the same source. In Lua each call returns a new userdata
  for it (they compare unequal).
- **What it carries:** every block, after the channel's effects and before its volume and pan, the channel's mix is
  copied into the source (the left side always; both sides, and whether it is stereo, only for a block in which the
  channel was active). The channel itself is still mixed as usual.
- **Rendering it** copies that block **over** the mix of the channel it was added to: whatever the sources added
  before it in that channel have mixed is replaced. Until its channel has produced a block, it renders nothing.
- **Order:** a channel source in a channel rendered before its own channel plays one block (256 samples) late.
- **Lua names:** in Lua the channel source's volume functions appear under other names (measured in the Simulator,
  `tests/probes/chsrcq`; the same on the device (3.1.2, by analysis)):
  `channelsource.new(source, left, [right])` sets the volume and `channelsource.remove(source)` returns it (`new`
  demands a channel source as its first argument; `remove()` returns 1.0, 1.0 and leaves the source in its channel). The
  volume does not change the copied block; unequal sides make the channel stereo.

`tests/probes/audchsrc` (five channels: the copy before the volume, the one-block delay, the overwrite, a source
refused by a second channel) is bit-exact.

### Custom C sources and effects

- `sound->addSource` and `channel->addCallbackSource` return sources; their callbacks run once per block from the
  render.
- `sound->effect->newEffect` returns an effect that keeps its userdata.
- **Effects on a mono channel get NULL for the right buffer.** A callback that does not allow for that crashes (the
  Simulator does).

### Activity

- A channel is active in a block when a source produced sound or an effect says so; an inactive channel adds nothing
  to the output.
- A delay line counts silent frames. Past its length it stops: it is not rendered and its ring does not advance, so a
  feedback tail ends one delay length after the input stops. Its taps go silent too.
- A two-pole filter stays active while its state is nonzero (it rings on); a one-pole filter always reports active.

## Effects

Effects run in the order added, on the channel's 8.24 samples. Each has a mix level (`setMix`, default 1): the wet
result is mixed with the dry signal by it, in fixed point. A mix of 0 leaves the block unchanged.

### Overdrive

Defaults: gain 1, limit 1, offset 0, mix 1. A hard clip, no soft curve:
- each sample is scaled by the gain (24 fractional bits, at most 127);
- it is clamped between (offset - limit) and (offset + limit) times 2^23 - 1, with those bounds ramping linearly
  across the block from the previous block's values;
- the result is mixed with the dry signal.

### Bitcrusher

- **Amount** (clamped to 0..1) gives a bit b = trunc(amount * 14.999) + 8 of the 24-bit sample. Bits below b are
  **cleared on positive samples and set on negative ones** (-1,382 becomes -1,281 in 16-bit terms). In 16-bit terms
  0.25 removes 4 bits, 0.5 removes 7, 0.75 removes 11, 0.9 removes 13.
- **Undersampling** u holds each crushed sample while a phase stays at or above 0. The phase starts each block at
  65536, drops by (1 - u) * 65536 per sample, and gains 65536 with each new sample. So 0.5 holds each value for 2
  samples. Undersampling of 1 or more leaves the block unchanged.
- The result is mixed with the dry signal, with 28 fractional bits.
- **SDK 3.1 settings** (`tests/probes/audbc`, exact):
  - `setDepth` and `setDownsampling` (each clamped to 0..1, plus their modulators' values) add powf(depth, 0.16) to
    the amount and powf(downsampling, 0.03) to the undersampling.
  - `setExponential(true)` makes the bit trunc(amount * 15.999) + 8 and moves the mask down by the sample's leading
    zero bits beyond 8, so quiet samples keep more of their bits.
  - `setAmount` clamps to 0..1, and `setUndersampling` makes negative values 0.

### Ring modulator

- Each sample is multiplied by a sine from the same 17-entry quarter-wave table the LFOs use (see
  [synth.md](synth.md)), at a 16-bit phase stepped by trunc(frequency * 65536 / 44100) per sample.
- The result is mixed with the dry signal (28 fractional bits).
- Both channels start from the same phase. An inactive block, or a mix of 0, leaves both the block and the phase as
  they are.
- With the default settings the measured output holds only the sum and difference frequencies, each at a quarter of
  the input level.
- **Negative frequencies** (a frequency modulator taking it below 0 Hz): on the device (3.1.2, by analysis) the
  float-to-unsigned conversion saturates at 0, so the phase holds and the input is multiplied by a constant. The
  Simulator's x86 conversion wraps, so its phase steps backward.

### Two-pole filter

- **Coefficients:** the cookbook (RBJ) biquads at exactly the set frequency, computed in single precision. The
  frequency over 22,050 Hz is clamped to 0..0.999 and multiplied by pi to give w.
- **Low-pass, high-pass, band-pass, notch and PEQ** use the bandwidth form with a bandwidth of (1 - resonance)
  octaves: alpha = sin w * sinh(ln 2 / 2 * (1 - r) * w / sin w), computed in double. This gives Q = 1.414 at
  resonance 0 and about 14.4 at 0.9. Band-pass is the constant 0 dB peak form.
- **Shelves** use Q = 1/sqrt(2) and ignore resonance, as documented.
- **Gain** (PEQ and shelves) is in decibels, A = 10^(gain / 40).
- The coefficients are recomputed only when the frequency, resonance or gain changes.
- The filter runs in single precision (rounded once, on the device (3.1.2, by analysis)), with the output clamped to
  32 bits and then mixed.
- **Edges:** a low-pass at 0 Hz or less, or a high-pass at 22,050 Hz or more, outputs silence and clears its state.
  The opposite ends leave the block unchanged.

### One-pole filter

- In fixed point. For p <= 0 (a low-pass): y = (1 + p) x - p y[-1], that is (1 - |p|) x + |p| y[-1].
- **For p > 0 the input passes unchanged**, although the documentation calls positive values a high-pass (measured
  for 0.2, 0.5 and 0.9).
- The state is kept as a float between blocks. A parameter or mix of 0 leaves the block unchanged.

### Delay line

- **`delayline.new(length, [stereo])`**: the length is in seconds in Lua (0.05 means 50 ms).
- **Wet signal:** the ring's sample from `length` frames ago (a pure delay), mixed with the dry input by the mix
  level. The ring then stores input + feedback * that sample (just the input with no feedback). In fixed point, 28
  fractional bits.

      wet[n]  = ring[n - N]
      ring[n] = x[n] + feedback * ring[n - N]
      out[n]  = (1 - mix) * x[n] + mix * wet[n]

- A mono line leaves the right channel dry; a stereo line has a ring per channel, and makes its channel stereo.

### Delay line taps

- **`delayline:addTap(delay)`** makes a tap, a source that adds the ring's sample from its delay ago, times its volume
  (`setVolume` / `getVolume`). In a stereo line the right ring feeds the right channel, swapped when the channels are
  flipped (`setFlipChannels`).
- **A tap is a source:** one that is never added to a channel is silent. Added to the same channel as its delay line,
  it feeds back into the line (an impulse repeats every tap delay at full level).
- **`setDelay`** takes only delays shorter than the line.
- **Delay changes:**
  - A delay modulator's value, in seconds, is added to the set delay as 44100 * value, truncated (rounded once, on
    the device (3.1.2, by analysis)).
  - When the delay to use differs from the last block's, the block plays the tap at the *set* delay fading out and at
    the new delay fading in. The fades move by i * (end - start) / ring length per sample (the ring's length, not the
    block's, in 32-bit arithmetic), so they never finish.
  - The next block with the same value reads at the set delay again. So a constant modulator has no effect, and a
    stepped one (a square LFO, a control signal) gives a one-block blend at each step. `setDelay` changes cross the
    same way.
  - A sweeping LFO shape (sine, triangle, sawtooth) reads instead from the set delay with a fractional step of
    1 + change / 256, interpolated in 16 bits. A change of 0x8000 frames or more skips the block's output.

`tests/probes/auddl` (6 cases) and `tests/probes/auddl2` (5 tap delay cases) are exact.

### Effect modulators

- An effect's modulators (LFOs, envelopes, control signals) are stepped once per block whenever the channel has
  sources or effects, active or not. Effect LFOs are not tied to notes.
- **Mix:** mix + modulator. Below 0 the block is skipped (the overdrive and the two-pole filter use 0); above 1 it is
  1.
- **Overdrive:** the limit and offset modulators are added.
- **Bitcrusher:** the amount and undersampling modulators multiply. The depth and downsampling modulators add, as
  above.
- **Ring modulator and two-pole filter:** the frequency modulator adds value * 22,050 Hz (in units of half the sample
  rate: depth 0.001 swings plus or minus 22 Hz, 0.01 plus or minus 220 Hz). At 0 Hz or below a low-pass outputs
  silence.
- **Two-pole filter:** the resonance modulator adds.
- **One-pole filter:** the parameter modulator adds.
- `set...Mod(nil)` clears a modulator.

`tests/probes/audfxmod` (7 cases) is exact. Effects are covered by `tests/probes/audio5` (overdrive, bitcrusher),
`tests/probes/audio6` and `audio7` (filters, ring modulator).

## The channel output stage and the final mix

After its sources and effects, each channel applies its volume and pan:
- **pan = pan + pan modulator; volume = volume * volume modulator.** A block is applied in pieces split at the
  modulators' events; a sweeping modulator ramps from the value it had at the end of the previous block.
- **Mono channel:** left gain v * min(1 - p, 1), right gain v * min(1 + p, 1). On the device (3.1.2, by analysis),
  games built with SDKs before 2.6 get the old law, max instead of min.
- **Stereo channel** (any stereo source, a source with unequal left and right volumes, or a stereo delay line): the
  near side keeps v * min(1 -/+ p, 1); the far side is cross-fed with gain v * |p| toward the panned side.
- A capture effect on the channel does not see the volume and pan; they come after.
- **Final mix:** the channels' sum in 8.24 is shifted right 8 bits and saturated to 16 bits.

`tests/probes/audout` and `audout2` (default channel, volume 0.5, pan -0.7 and 0.4, sine and square LFO pan and
volume modulators, four loud notes saturating, a stereo channel panned -0.5) are bit-exact in the final output.

## Signals

- **Channel level signals:** `channel:getDryLevelSignal()` and `getWetLevelSignal()` return
  `playdate.sound.signalvalue` objects (not `playdate.sound.signal`). That class has only `getValue`. They can be
  used as any modulator (player rates, channel volume and pan, synth frequency, amplitude and parameters, effect
  parameters).
  - A level is measured only while the signal is in use; assigning it as any modulator marks it in use. A fresh
    channel's signal reads 0.
  - **Value:** each block's peak absolute sample as a fraction of full scale; the dry signal before the channel's
    effects, the wet signal after them. Stereo takes the larger side, and a silent block reads 0. A square wave at
    volume 0.5 reads about 0.50 dry; through an overdrive with gain 3 it reads 1.0 wet. Which block a frame reads
    depends on where the audio stream is when the frame runs (`tests/probes/chlevel`).
- **`signal->newSignalForValue`** (C) returns a signal for an LFO or envelope.
- **`getValue`** on any signal returns its value at the last block step.
- On the device (3.1.2, by analysis) the signal classes' metatables have no `__gc`.

## Other sound functions

- **`playdate.sound.playingSources()`** counts an instrument as one source.
- **`sound.getHeadphoneState()`** returns two booleans, headphones and microphone. The Linux Simulator reports
  headphones connected (true, false). The C call in the Simulator leaves its outputs untouched.
- **`sound.setOutputsActive`** (C) aborts the Simulator when it has no audio device.
- **Microphone:** `micinput.getLevel()` returns a float and `micinput.getSource()` returns "device".
  `micinput.requestAccess()` exists.
- **`playdate.getSystemVolume()`** exists.
- **`playdate.setCrankSoundsDisabled(flag)`** returns whether crank sounds were disabled before, so false (0) at
  first.
- **Lua class field:** each sound class table has a `userval_count` (synth 6, fileplayer 8, sampleplayer 7, channel
  6; 0 for signals); see [../lua/objects.md](../lua/objects.md).
