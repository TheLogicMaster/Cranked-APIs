# Samples, sample players and file players

This file covers sound data and the two players: `playdate.sound.sample` and C `sound->sample` (loading, formats,
lengths, buffers), the compiled `.pda` format with its PCM and IMA ADPCM encodings, MP3 files, `sampleplayer`
(fixed-point playback, play ranges, rates, loops, ping-pong, offsets, pause and stop fades, callbacks) and
`fileplayer` (the streaming reader and ring buffer, loops, offsets, fades, underruns, callbacks). Behaviour is stated
as it is on the device (3.1.2, by analysis); where a probe is cited, the Simulator (SDK 3.1.1) was measured against it
and matches unless a difference is noted. The block grid, channels and the audio clock are in
[effects.md](effects.md); sample-based synths in [synth.md](synth.md).

## Formats

| `SoundFormat` | Value |
| --- | --- |
| `kSound8bitMono` | 0 |
| `kSound8bitStereo` | 1 |
| `kSound16bitMono` | 2 |
| `kSound16bitStereo` | 3 |
| `kSoundADPCMMono` | 4 |
| `kSoundADPCMStereo` | 5 |

`SoundFormat` is one byte in C games built with the SDK (the ARM EABI's short enums), so `sound->sample->getData` stores
one byte through its format pointer and leaves the bytes after the game's variable untouched (`tests/probes/enumq`).

### The `.pda` file

    bytes 0-11   "Playdate AUD" (no terminator)
    bytes 12-15  little-endian word: sample rate = word & 0xFFFFFF, format = word >> 24
    then the sample data

A common mistake is to compare the magic as a NUL-terminated string, or to take the two fields from the wrong ends
of the word.

- **8-bit PCM is signed** (silence is 0): sample16 = (int8) byte << 8. This is measured from `pdc` output and
  captured playback; some third-party format notes say unsigned, which is wrong.
- **16-bit PCM** is little-endian signed, stereo interleaved.
- **IMA ADPCM** (formats 4 and 5):

      2-byte block size, then the blocks (the last block may be partial)
      each block: per channel a 4-byte header: a signed 16-bit predictor (which is also the block's first sample),
                  a step index byte, a zero byte
                  then the 4-bit codes; mono: high nibble first; stereo: high nibble left, low nibble right

  The length comes from the decoded frames, not the compressed size. Measured for test samples of 11,025 frames:
  0.5000 s mono and 0.4990 s stereo.

ADPCM blocks are independent (each header holds its predictor and step index), so a player can decode a block the
first time a frame in it is read instead of decoding the whole sample at load; the output is the same.

An audio file can also be compiled into the game's `main.pdz` by `import`; the loaders find it there by name (see
[../data/files.md](../data/files.md)).

## Samples

### Loading and creating

- **`sound.sample.new(path)`** (Lua) and **`sound->sample->load(path)`** (C) load a compiled `.pda`. For a 0.5-second,
  16-bit mono, 22,050 Hz file they report format 2, rate 22050 and length 0.5.
- **Missing file:** Lua returns nil and "file <path> not found: No such file" (the path as given, for example
  "file nope not found: No such file").
- **Where sounds are found:** `sample.new`, `sampleplayer.new` and `fileplayer.new` with a path look in the game's data
  folder first, then the bundle. A `.pda` the game wrote with `playdate.file` loads by name, and one in the data folder
  is used instead of the bundle's file of the same name (`tests/probes/audfdata`).
- **`sample.new(seconds, [format])`:** allocates an empty buffer at 44,100 Hz. Without a format the buffer is 16-bit
  stereo (format 3) (`tests/probes/retq`).
  - With more seconds than the heap holds: on the device (3.1.2, by analysis) it fails and returns nil (check on
    hardware). The Simulator has more memory and returns a sample.
- **`newSampleBuffer(bytes)`** (C): 16-bit stereo at 44,100 Hz, so 88,200 bytes is 0.5 seconds.
- **`loadIntoSample` and `sample:load(path)`:** load into an existing buffer, and fail (false or 0) when the file does
  not fit it.
- **`newSampleFromData`:** creates a sample from the game's own bytes. The sample plays those bytes, and so does a
  buffer from `newSampleBuffer` that the game fills: the data must be read when played, since the game may have
  written it since the sample was made.

### Reading back

- **Lengths** are in seconds, computed from the frame count, the format and the sample's own rate.
- **`sample:getLength()`** returns two values: the recorded length and the buffer's capacity. A buffer from
  `sample.new(seconds)` reports (0, seconds); a loaded sample reports (length, 0).
- **`getSubsample(start, end)`** takes frames. On a buffer not yet recorded into (length 0) it returns nil. An empty
  range must not copy from a null buffer.
- **`sample:save(path)`** writes a file.
- **`sample:decompress()`** returns a boolean.

## Fixed-point playback (sample players, file players, sample synths)

All three play sample data the same way:

    step = trunc(sampleRate * rate * 65536 / 44100)      (single precision)
    position = (frame, 16-bit fraction f)
    interpolate if:  mono:   frame - base < avail - 1
                     stereo: 2 * (frame - base) < avail - 2
    value = interpolate ? (f * s[frame + 1] + (65536 - f) * s[frame]) / 256   (divided toward zero)
                        : s[frame] << 8
    added with volume trunc(min(volume, 7) * 2^28), as a synth sample is (see synth.md)
    f += step; frame += f >> 16; f &= 0xFFFF

- base and avail are 0 and the sample's frame count; for ADPCM, the frame at the block's start and the frames that
  block needs, ((256 * step + f + 0xFFFF) >> 16) + 1.
- No interpolation on the last frame.
- **The stereo quirk:** **stereo audio interpolates only in the first half of its data** and holds each value for the
  second half. ADPCM is decoded per block into a buffer of just the frames that block needs, so stereo ADPCM
  interpolates for the first half of every 256-sample block and holds values for the second half (at 22,050 Hz, 128
  samples each). Mono interpolates throughout.
- Gain is unity: a sample at volume 0.5 and 0.25 peaks at 4,000 and 2,000 from 7,999. Left and right volumes scale
  linearly.

## Sample players

### Creating and state

- **`sampleplayer.new(sample or path)`** accepts either. A missing file gives nil and "file nope not found: No such
  file". Volumes set with `setVolume` read back with `getVolume`.
- **`play([repeatCount], [rate])`** and **`playAt`** return booleans. An omitted `repeatCount` means 1 (play once);
  0 loops forever. (A common trap: defaulting the omitted count to 0 makes every one-shot sound loop.)
- **`isPlaying`:** `play` only schedules the start; the next render that reaches the start time begins playback.
  Until then `isPlaying` reports the pending start as true. Pausing does not cancel a pending start, so a sample
  player paused right after `play()` still reports true (and then starts anyway). Once started, a paused sample
  player reports false.

### Lifetime

In the Simulator (SDK 3.1.1), with the game keeping no reference to the player (`tests/probes/audspgc`):

- **A player that never played** is collected by the next full garbage collection.
- **A player that is playing** is kept alive until it finishes, whether or not it has a finish callback; the finish
  callback runs, and the next collection takes the player. So `sampleplayer.new(path):play()` with no reference kept
  plays to the end.
- **Memory is given back:** making and dropping 400 players, each loading its own copy of a one-second stereo sound
  (about 70 MB in all), never fails.

For an implementation, this means a dropped player must release its sample's memory. A game that makes a player per
event (Godspeed makes one per obstacle) runs out of the 16 MB heap after a few minutes otherwise. A playing source is in
the default channel until it finishes (see [effects.md](effects.md)), so the channel's hold on it must not keep it
alive once it has stopped. The device was not measured; check on hardware.

### Start and play range

- **Start:** the next render that reaches the start time takes the pending play range, offset, rate and repeat count.
  Lua `playAt(when, [vol], [rightVol], [rate])` starts at audio time `when` and plays once at that volume. While a
  `playAt` volume applies, `setVolume` is kept for later.
- **Play range** (`setPlayRange`): set on a stopped player it applies to the next play only; set while playing it
  applies at once. An end of 0 means the sample's end. Interpolation stops at the range's end, not the sample's.
- **Offset:** `setOffset` on a stopped player sets where the next `play()` starts; on a playing player it moves the
  play position. `getOffset` reports the current position, so it stays 0 after `setOffset` on a stopped player.

### Direction, loops and rate

- A **negative rate** plays backward from the range's end.
- **Repeat count:** 0 loops forever, n plays n times, -1 plays back and forth (ping-pong). A forward loop restarts at
  the range's start; a backward loop restarts at its end. Ping-pong turns around where it stopped, so the turn reads
  one frame past the range's end.
- An empty range with infinite repeats makes the render loop forever; an emulator should stop for that block.
- **`setRate`** changes the current play's speed and the stored rate. `play`'s own rate argument does not change the
  stored rate. `setSample` resets the stored rate to 1.
- **Rate modulator:** the modulator's value scales the step. The block is split at an LFO's event, and the value from
  before the event is used for the part before it. Smooth shapes sweep the step from the last value. Envelopes and
  control signals give one value per block (they have no events).
  - A sample player's rate modulator runs whenever the player is in a channel, even while it is stopped, so an LFO's
    phase at `play` depends on how long the player has been in its channel.

### Stop, pause and callbacks

- **`stop` and `setPaused(true)`** both fade the output to 0 over one block; resuming fades in over one block.
- **`stop`** calls the finish callback at once if the player was playing.
- **C callbacks:** the loop callback runs after each loop, and the finish callback when the last pass ends, both from
  the audio render.
- **Lua callbacks** (`setFinishCallback`, `setLoopCallback`) run on the main thread before the next update; the
  Simulator calls the finish callback within one or two audio blocks of the sound ending.

`tests/probes/audsp` (11 cases: ranges, loops, reverse, ping-pong, stop and pause fades, offsets, mid-play rate and
range changes, stereo), `tests/probes/audsp2` (rate LFOs) and `tests/probes/audspm` (envelope and control-signal rate
modulators) match sample for sample, together with the logged offsets, `isPlaying` values and callback counts.

## File players

A file player streams its file from storage, so a game may open many long tracks within the device's 16 MB (keep
decoded file-player data out of the emulated heap).

### Opening and errors

- **`fileplayer.new([path], [bufferSeconds])`**; a missing file gives nil and a message of the form "Couldn't load
  file at <path>: <reason>" (the Simulator gives "Couldn't load file at nope: No error").
- **Path lookup:** a path is tried as given, then with `.pda`, then with `.mp3`.
- **`fileplayer:load(path)`:**
  - while playing: false and "file already playing"; the old file keeps playing (`tests/probes/fpq`);
  - for a missing file: false and "Invalid argument".
- **`getLength()`** without a file: nil and "The file at (null) could not be loaded".
- **When the file is opened:** at the first `play`, `getLength` or `setBufferLength` (Lua `setBufferSize`; the buffer
  size given to `fileplayer.new` does not open it). Before that the file's rate is unknown: `getOffset` gives 0, and
  `setOffset` keeps the seconds and applies them when the file opens (`tests/probes/luafp2`).
- **`setBufferSize`** raises an error while playing. It reallocates the ring, which loses what it held.
- Loading a file clears the loop range.

### Playing without a file

A file player that was never given a file, or whose `load` failed, has nothing to open:
- `play()` returns true;
- `isPlaying()` stays true across frames, with the offset at 0 and no underrun, until `stop()`;
- while it is in that state, `load` is refused with "file already playing".

(`tests/probes/fpnone`.)

### The reader and the ring buffer

- A **reader** copies the file's data into a ring buffer. It runs when the player starts and once per frame, and
  fills the ring until 4 bytes are left free.
- The **ring** holds `bufferSeconds` (0.25 by default) * 44100 frames in the file's bytes per frame (ADPCM counted as
  16-bit), rounded up to a multiple of 4 bytes.

Reader, per run:

    while the ring holds less than its capacity:
        end = (repeats != 1 and loopEnd) ? loopEnd : file end
        if position >= end:
            if repeats == 1: stop reading (end of data)
            else: repeats -= 1 unless it is 0 (forever); position = loopStart; run the loop callback
        else copy min(free, end - position) frames into the ring

### Rendering

Each 256-sample block plays from the ring's read pointer:
- A **contiguous region** ends at the ring's end or at the end of the data read so far, and interpolation stops on the
  region's last frame (a 22,050 Hz file shows this every 11,026 frames).
- **The fraction is dropped:** the block starts with the sub-frame fraction the player had before it, and the fraction
  reached by the block's end is discarded. So a step that is not a whole number of frames per block plays slightly
  slow: about 0.4% for a 32 kHz file, 0.2% for 48 kHz, and the same for rates other than 1.
- **Step:** rate * 65536 * fileRate / 44100, converted to unsigned. On the device (3.1.2, by analysis) a negative rate
  gives step 0 (the player holds its frame); in the Simulator the x86 conversion wraps to a huge step.
- **Volume 0:** at volume 0 on both sides nothing is read or written, so the player does not advance until its volume
  is raised.
- **Rate modulator:** the value scales the step; an LFO's block is split at its event (the value before the event for
  the part before it), interpolating shapes sweep the step from the last part's value, and envelopes and control
  signals give one value per block.
  - With a sine LFO as the rate modulator, on the device (3.1.2, by analysis) the player plays at the LFO's value,
    one value per block (check on hardware); the Simulator (SDK 3.1.1) stops with SIGFPE in the first block.

Render, per block:

    f0 = fraction
    step = unsigned(rate * 65536 * fileRate / 44100), scaled by the rate modulator
    repeat: region = min(ring end - read pointer, frames held)
            if region == 0: stop, or an underrun
            if either volume > 0: play from the read pointer like a sample (no interpolation past the region's
                last frame), then move the read pointer by the whole frames passed
    fraction = f0

### Loops

- `setLoopRange(start, [end], [loopCallback])` and the repeat count are handled by the reader.
- At the end of a pass (the loop end if one is set and this is not the last pass, else the file's end) the count goes
  down by 1 (0 is forever), the reader goes back to the loop start, and the loop callback runs. That happens up to a
  buffer ahead of what is heard.
- The last pass plays to the file's end. With 2 plays and a loop range, that is start to loop end, then loop start to
  the file's end.
- A loop end at or before the start means the file's end.

### End and underruns

- When the ring is empty after the last pass, the player stops: its finish callback runs, and the next play starts
  over.
- An empty ring before that is an underrun (`didUnderrun` becomes true). With `setStopOnUnderrun(true)` the player
  stops there too.

### Offsets

- **`getOffset`** is the reader's position less what the ring holds, counted in whole frames of the file and
  reported in seconds.
  - A value below the loop start is taken for the end of a loop still in the ring, so (loop end or file end) - loop
    start is added. During the first pass, before the loop start, it therefore reads that much too far.
  - A stopped player reports 16 bytes (the file header) more, for example 0.000181 s for 16-bit mono at 44.1 kHz.
- **`setOffset`** on a stopped player empties the ring and starts there. On a playing one the reader moves, and what
  the ring already holds still plays first, so `getOffset` right after reads the new offset less the buffer (games
  that time notes by `getOffset` see 0.25 s of buffered audio after `play()` then `setOffset`).

### Stop, pause and play

- **C `stop`** returns the player to the start, calls the finish callback when it was playing, and takes the player
  out of its channel; the next `play` adds it to the default channel.
- **Lua `play`** puts the player back in the channel Lua added it to, and Lua's `stop` also returns to the start.
- **`pause`** keeps the position, and `play` continues from it. A paused file player reports `isPlaying()` false.
- **Lua `play()` without a count** keeps the last count unless the offset is below 1 frame; in that case it plays
  once, or forever when a loop range is set. A loop start after 0 makes the offset look mid-file (see Offsets), so
  `setLoopRange(0.5, 1); play()` plays once (measured).
- **`setPaused(flag)`:** true pauses; false plays as `play()` with no count.
- **`isPlaying`** returns a boolean.

### Volume and fades

- **`setVolume(left, [right], [fadeSeconds], [callback], [arg])`** (Lua): with a fade time above 0 the volume fades to
  the target over that time. When the fade ends the callback runs once, with the player and `arg`.
- **C `fadeVolume`** takes the length in samples and a callback.
- The fade advances during playback, block by block, and the volume reached is written back as the player's volume, so
  `getVolume` reports it during the fade. Negative targets are 0.
- Setting a volume without a fade cancels a running fade and its callback.

`tests/probes/luafade` (fade down, fade up with different sides, a cancelled fade): `getVolume` agrees within the block
timing, and the callbacks run on the same frames as in the Simulator.

### MP3 files

- An ID3v2 tag is skipped.
- **Length:** `getLength` is estimated from the first frame's bit rate: data bytes * 8 * rate / bit rate. That is exact
  for a constant bit rate; for a variable one it can be far off (7.1 s for a 3.1 s file whose first frame is the
  encoder's info frame at 64 kb/s).
- **Playback** plays every frame that decodes, whatever the estimate.
- **Offsets** of a variable-bit-rate file follow the same estimate on the device (3.1.2, by analysis).
- A float decoder such as minimp3 agrees with the Simulator (SDK 3.1.1) in timing and length and within 2 units of
  16 bits (RMS 0.25 unit) (`tests/probes/audmp3`).

`tests/probes/audfp` (8 cases) and `tests/probes/audfp2` (6 cases, rate modulators) are exact on every sample apart
from the frame timing of stop and play; `tests/probes/luafp` and `luafp2` cover the Lua side.
