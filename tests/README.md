# Test probes

The probes are small Playdate programs, in Lua and in C, that exercise one API behaviour each and write what they
see: return values, pixel dumps, hashes of drawn images, timings of callbacks, audio captures. Each probe runs
unchanged in the Playdate SDK 3.1.1 Simulator and in an emulator under test, and the two outputs are compared. The
Simulator output is the reference, except where a probe or its README says otherwise.

This folder holds:

- `probes/<name>/`: one folder per probe (index below);
- `tools/`: fuzzers, a Simulator driver and comparison scripts used with the probes.

## Layout of a probe

| Path | Contents |
| --- | --- |
| `Source/main.lua` (and other `.lua`, `pdxinfo`, assets) | Lua probes, and the Lua side of C + Lua probes |
| `src/*.c`, `Makefile` | C probes (the SDK's standard C Makefile) |
| `expected/` | output recorded in the Simulator (SDK 3.1.1) |
| `*.py`, `*.sh` | analysis or driver helpers, where the probe has them |
| `input.txt`, `timeline.txt`, `actions.txt`, `sim_actions.txt` | scripted input, where the probe needs it |
| `README.md` (where present) | notes: assets to supply, files left out, how to use the helpers |

Assets included in `Source/` are made for the probes (synthetic sine, noise and impulse sounds, tiny MIDI files,
small random or patterned test images, `.strings` files). Fonts and images from the SDK or from games are not
included; a probe that needs one says so in its README, with what to supply.

## Building

Set `PLAYDATE_SDK_PATH` first (pdc finds CoreLibs through it, or through `-sdkpath`):

    export PLAYDATE_SDK_PATH=/path/to/PlaydateSDK-3.1.1

Lua probe:

    $PLAYDATE_SDK_PATH/bin/pdc Source <name>.pdx

C probe (builds the Simulator library and the device binary, then the pdx):

    make

C + Lua probes (a C part that registers functions for Lua) build with `make` as well. An emulator runs the device
binary (`pdex.bin` in the pdx); the Simulator loads the host library (`pdex.so` / `pdex.dylib` / `pdex.dll`).

## Running in the Simulator

Open the pdx in the Simulator (`PlaydateSimulator <name>.pdx`). Text a probe prints goes to the Simulator's console.
Most probes write their results to a file in the game's data folder instead, `<SDK>/Disk/Data/<bundleID>/`, and then
call `playdate.simulator.exit()`. The bundle ID is in `Source/pdxinfo`; many probes share `org.crankedapis.probe`, so
clear that data folder before each run. Probes that need scripted keys or crank input come with an actions file for
`tools/sim/simkeys.sh` (Linux, Xvfb and xdotool).

## Running in an emulator under test

Run the pdx headless for a time budget, keep the game's console output, and collect the files it writes to its data
folder (`<bundleID>/`). Features that help:

- a virtual clock that advances a fixed step per loop without sleeping, so the budget is in game time and runs repeat;
- capturing the final audio output (16-bit stereo, interleaved) and the last displayed frame to files;
- a mode that mixes no audio, as the Simulator does without an audio device;
- scripted input from a timeline file, in the format below.

The input timeline is a text file with one event per line, `<ms> <buttons> <crankAngle> <docked>`: from
time `<ms>` (since the first update) the button state is `<buttons>` (the SDK's button bits: left 1, right 2, up 4,
down 8, B 16, A 32), the crank angle is `<crankAngle>` degrees and the crank is docked when `<docked>` is 1. See
`probes/inp/timeline.txt` and `probes/btncb/input.txt`.

### Runner interface

The scripts in `tools/` and the probe drivers (`probes/cprobe/drive.py`, `probes/rotctr/run.sh`) run an emulator
through a headless runner command and expect this of it:

- it is invoked as `<runner> <pdx> <seconds> [timeline]`: the game runs for `<seconds>`, then the runner exits; the
  optional third argument is an input timeline file in the format above;
- the game's data folder is `./appData/<bundleID>/` in the current directory: files already there (configuration and
  skip lists the fuzzers write before a run) are visible to the game, and what the game writes stays there after the
  run;
- the game's console output (`print`, `logToConsole`) goes to stdout, one line per call; the runner's own messages
  and errors go to stderr;
- with `RUNNER_VIRTUAL_CLOCK=1` in the environment, time advances by a fixed step per frame without sleeping, so a run
  is deterministic (`tools/fmtfuzz/` and `tools/scanfuzz/` set it).

`RUNNERS` (for `fmtfuzz/run.sh` and `scanfuzz/run.sh`) is a space-separated list of runner commands; a `+` inside one
stands for a space, so a command can carry arguments or environment settings (`env+VAR=1+/path/to/runner`).

## Expected output

`expected/` holds what the probe produced in the Playdate SDK 3.1.1 Simulator (Linux): the probe's output file
copied from the Simulator's data folder, or its console log, under the original file names (`sim.txt`,
`sim_log.txt` and `<name>.txt` are all Simulator results). Exceptions are noted in the probe's README (for example
`fmtq/expected/ref.txt` is the host C library's output, and `rotctr/expected/expected.raw` is raw pixels).
Outputs over 2 MB are left out and named in the probe's README. Audio probes write raw captures of what their
capture effect saw; those captures are not included, and the Python helpers next to such a probe analyse a capture
from either environment.

To compare, run the probe in the emulator and diff its output file with the expected one. For tab-separated case files
(`name<TAB>result` per line) `tools/compare/diff.py <sim> <emu>` and `diff3.py <sim> <emu> <out.json>`
report the cases that differ, treating integer/float subtype differences separately.

Some probes depend on the time or on the host (timers measured by clock, `timeq`, `numtype`, `perfq`); their
expected output shows the form of the result rather than exact values.

## Tools

| Tool | What it does |
| --- | --- |
| `tools/luafuzz/` | Lua API fuzzer: calls every function in the playdate tables, and every method of the classes it can instantiate, with random arguments inside pcall; `run.sh <runner> [seconds]` (the emulator runner binary is required) reruns it, skipping a function that crashed or hung, and records findings in findings.txt |
| `tools/cfuzz/` | C API fuzzer generated from the SDK headers (`gen.py`, run in that folder with PLAYDATE_SDK_PATH set, writes `src/main.c` from `main_template.c`); build with `make device`, run with `run.sh <runner> [seconds]` (runner binary required) |
| `tools/fmtfuzz/` | differential printf fuzzing: `gen.py` writes random cases, the probe formats them through the C API, `ref.c` through the host's snprintf; `run.sh <count> <seed...>` (RUNNERS, required, lists runner commands) |
| `tools/scanfuzz/` | the same for `parseString` against the host's sscanf |
| `tools/dispfuzz/` | one random display configuration per run (scale, offset, flips, inversion, background), for comparing displayed frames between builds |
| `tools/stfuzz/` | random image draws through random stencils, with a hash of the target after each case, for comparing builds |
| `tools/sim/simkeys.sh` | run a pdx in the Simulator under Xvfb and replay an actions file (`sleep`, `key`, `down`, `up`, `wheel` lines) |
| `tools/compare/` | `diff.py` and `diff3.py` for case files; `diffview.py <a> <b>` and `diffregion.py <a> <b> x0 y0 x1 y1 step` for 400x240 frame dumps (hex rows separated by `/`), marking pixels set in one only |
| `tools/imggen/gen.py` | writes the generated test images several probes share (figure.png, cursor.png, panel.png, marks-table-24-24.png) into their `Source/` folders; `arrow/gen.py` and `itlen/gen.py` do the same for those probes |

## Probe index

| Probe | Language | What it checks | Expected output |
| --- | --- | --- | --- |
| accel | Lua | Accelerometer values and running state before, during, and after start/stop, over frames | yes |
| adpcm | Lua | Sample formats, rates and lengths of 8-bit PCM and IMA ADPCM (mono, stereo) WAV files | no |
| allspr | Lua | The order of gfx.sprite.getAllSprites() with z indices, before and after an update, after z changes, removals and re-adds | yes |
| alphaq | Lua | sprite:alphaCollision at fractional positions, flips, partial or missing collide rects; gfx.checkAlphaCollision | yes |
| alphaq2 | Lua | checkAlphaCollision and sprite alphaCollision with an image that has no mask | yes |
| animq | Lua | Animator with point values, delay and easing driving a sprite; logs per frame | yes |
| apilist | Lua | Every function reachable from the playdate table (no CoreLibs), to compare the API surface | yes |
| arceq | Lua | Equality of geometry objects with equal fields | yes |
| arcg | Lua | geometry.arc length, pointOnArc (with and without extend), and default direction | yes |
| arcs2 | Lua | Ellipse arcs and pies (fill and outline, widths 1, 2, 5), drawArc, and rounding of negative halves | yes |
| arcs3 | Lua | Random ellipses, arcs and pies (sizes, widths, stroke locations, fractions, clipping, odd angles) | yes |
| arrow | Lua | A sprite made without an image that sets its image in its own update | yes |
| audbc | C | Bitcrusher settings from SDK 3.1 on a sine note (0.5 s, 330 Hz, decaying envelope) | no |
| audchadd | C | Which channels are mixed (never added, added, added and removed, added twice) | no |
| audchsrc | C | A channel's output as a source (channel->getOutputAsSource) | no |
| audclock | C | The audio clock (sound->getCurrentTime) seen by each of the first 60 updates, and by init | no |
| audcs | C | Control signals as modulators of amplitude, frequency and a channel filter | no |
| auddl | C | Delay lines (length 3000) after a short note: no feedback, feedback 0.5 and 0.9, mix 0.5, a stereo line, and a tap with the line's mix at 0 | no |
| auddl2 | C | Delay line taps with delay modulators (LFOs, control signal, changed delay) | no |
| audenv | C | Envelope timing with a 1 Hz square (constant level, so each sample shows the amplitude) | no |
| audenv2 | C | Envelope curvature, velocity sensitivity, rate scaling and legato on synth envelopes | no |
| audenv3 | C | A synth note started while the previous one still sounds (sustain, release, retriggered release), with and without the envelope's retrigger flag | no |
| audenv4 | C | Legato envelopes (the audenv3 cases with setLegato(1)), plus notes without a length | no |
| audenv5 | C | Envelopes as synth modulators (frequency, amplitude, parameter), with scale, offset, velocity sensitivity, sharing, retrigger, curvature, note-off retrigger and legato | no |
| audfdata | Lua | Sounds load from the data folder first (a `.pda` the game wrote), and listFiles names a file in both places once | yes |
| audfp | C | File players at rates other than 1 and with rate modulators | no |
| audfp2 | C | File players: rate modulators, volume, loop ranges, buffer size, stop and replay, getOffset log | yes |
| audfxbase | C | Baseline for audfxmod (the same channels and notes, no effects) | no |
| audfxmod | C | LFO modulators on effects (overdrive limit and mix, bitcrusher amount, ring modulator frequency, two-pole frequency and resonance, one-pole parameter) | no |
| audio10 | C | Frequency modulation units (square LFO on a synth's frequency) | no |
| audio11 | C | An LFO on a two-pole filter's frequency, probed with impulses every 0.25 s | no |
| audio12 | C | Channel volume and pan, captured after the channel by routing its output into another channel | no |
| audio13 | C | Sequence playback timing and velocity, captured from the default channel | no |
| audio14 | C | MIDI playback with a one-voice and a two-voice instrument (voice allocation for a chord) | no |
| audio14w | C | MIDI playback with a one-voice and a two-voice instrument (voice allocation for a chord) | no |
| audio15 | C | Sequence loops (setLoops), captured as note onsets | no |
| audio2 | C | Capture the main channel mix while playing a timed list of synth notes | no |
| audio3 | C | Capture playback of 8-bit and IMA ADPCM samples (mono and stereo), left and right separately | no |
| audio4 | C | Measure source volumes and the default channel's volume and pan, capturing left and right | no |
| audio5 | C | Measure memoryless effects (overdrive, bitcrusher) on a sine, captured after the effect | no |
| audio6 | C | Impulse responses of the effects with memory, captured after the effect | no |
| audio7 | C | Impulse responses of the remaining two-pole types, a ring modulator on a sine, and a delay tap | no |
| audio8 | C | Block sizes, an unadded delay tap, and noise register continuity | no |
| audio9 | C | LFO shapes, seen as the amplitude envelope of a sine note they modulate | no |
| audioc | C | Capture the mixed audio of the main channel through a custom effect | no |
| audiocap | Lua | A sample player and two synth notes at fixed frames (for an audio capture) | no |
| audlfo | C | Synth frequency and amplitude modulators (LFOs), notes scheduled on the audio clock | no |
| audlfo2 | C | LFO behavior beyond single fresh notes: running phase across notes, retrigger and start phase, delay and ramp, arpeggios, a shared LFO, a global LFO | no |
| audlfofn | C | Function LFOs (setFunction), with and without interpolation, as frequency and duty modulators | no |
| audmidi | C | MIDI pitch bend through a sequence: RPN 0 sets the track's range, which the instrument gets when set on the track (0 when the file has no RPN); bends are applied per block | no |
| audmp3 | C | MP3 file players (128 kb/s mono, VBR stereo, 22.05 kHz with an ID3v2 tag): length, offsets, playback | yes |
| audout | C | The final output mix: default channel, pan and volume LFOs, volume and pan, loud notes at once | no |
| audout2 | C | The final output mix, part 2: volume and pan, loud notes at once, a stereo synth panned | no |
| audsamp | C | Sample-based synths (setSample): pitch, sustain loops, release, the 2756 Hz cap, formats, volume | no |
| audseqoff | C | sequence->allNotesOff called from the audio thread while two long notes play | no |
| audseqoff3 | C | sequence->allNotesOff from the main loop with a sequence note and a direct instrument note | no |
| audsp | C | Sample player play ranges, reverse, ping-pong, loops, stop and pause fades, offsets, rate changes, and loop and finish callbacks | no |
| audsp2 | C | Sample players with rate modulators; otherwise as audsp: play ranges, reverse, ping-pong, loops, stop and pause fades, offsets, rate changes, and loop and finish callbacks | no |
| audspgc | Lua | When dropped sample players are collected: kept while playing (finish callback runs), idle ones at once; 400 loads never run out of memory | yes |
| audspm | C | Sample player rate modulators other than LFOs (control signals, envelopes) | no |
| audstress | Lua | Random file player, sample player and delay tap operations every frame; must not crash or hang | no |
| audsw | C | Synth waveforms at several frequencies (band limiting) | no |
| audtab | C | Synth notes whose phase steps land on exact wavetable entries; rec.py reads the sampled waveform back from a capture | no |
| audte | C | Teenage Engineering generators (POPhase, PODigital, POVosim), parameters and modulators | no |
| audwt | C | Synth waveforms at several frequencies (band limiting), and two noise notes on one synth | no |
| audwtab | C | Wavetable synths (setWavetable, parameters 1-4), notes scheduled on the audio clock | no |
| audwtab2 | C | Wavetable synths (setWavetable, parameters 1-4), notes scheduled on the audio clock | no |
| bg | Lua | setBackgroundColor and when the background reaches the working and display images | no |
| bgclear | Lua | Is the dirty area cleared before the background callback? | yes |
| bgfirst | Lua | On which frames a background drawing callback runs, after a start-up sequence such as games use | yes |
| bgredraw | Lua | A background drawing callback that calls sprite.redrawBackground() and changes the draw offset and clip rect inside itself, with a sprite on top | yes |
| bigfont | Lua | Loading a large bitmap font from Lua and its metrics | no |
| bigfontc | C | Loading a large font through the C API | no |
| blurd7 | Lua | blurredImage and drawBlurred over random images: radii 0 to 6, passes, dither types, phases, clipping, flips | yes |
| blurq | Lua | blurredImage and drawBlurred with masks | yes |
| blurq2 | Lua | What lies outside an image for blurredImage | yes |
| blurq3 | Lua | blurredImage and drawBlurred over random images: radii 0 to 6, passes, dither types, phases, clipping, flips | yes |
| blurq4 | Lua | drawBlurred near the left and top edges (Bayer 4x4, an opaque striped image), to place the pattern | yes |
| btncb | C | system->setButtonCallback: each callback (button, down, frame) and the update count | no |
| caps | Lua | Round and square line caps on vertical, horizontal, and diagonal lines, integer and fractional widths | yes |
| cbench | C | Native speed (register, heap, frame buffer, stack, static stores), self-modifying code and bitmap row padding | no |
| ccdepth | Lua | How many nested pcall levels fit before "C stack overflow" from the main chunk, update, coroutines and callbacks | yes |
| chlevel | Lua | A channel's dry and wet level signals, unused and used as modulators, with a steady square wave | yes |
| chsrcq | Lua | playdate.sound.channelsource.new and remove, signalvalue, and the source base methods | yes |
| circ1 | Lua | 1-pixel circle outlines (drawEllipseInRect, square rects) for sizes 1..40, plus a few positions | yes |
| circw | Lua | Wide circle outlines (centered stroke) for odd and even sizes 5..39, widths 2..5 | yes |
| cjson | C | The C API JSON decoder (callback sequence, paths, values, errors, skipping, returnString) | yes |
| clipdirty | Lua | Which image changes redraw a sprite showing that image without markDirty | yes |
| cloop | C | an update callback that never returns on its third frame: the emulator must stop it rather than hang | no |
| collq | Lua | moveWithCollisions and checkCollisions results for every response type, groups and odd cases | yes |
| coq | Lua | Coroutines started from a timer callback, drawing into an image and yielding (as a game's loader does) | yes |
| coroq | Lua | Which thread runs the main chunk, the update callback and other callbacks | yes |
| coroq2 | Lua | A yield in the main chunk; when does the rest run, and does update run before it | yes |
| cprobe | C | C API cases across system, display, files, graphics, tilemap, video, sprites, JSON, sound, network and scoreboards | yes |
| crankacc | Lua | getCrankChange's two values while the crank is turned (mouse wheel in the Simulator) | yes |
| csrvtime | C | C getServerTime without a network, and getLaunchArgs' path | yes |
| ctxq | C + Lua | Which graphics state the C API and Lua share (setters on one side, drawing on the other) | yes |
| dd13 | Lua | Differential drawing: random drawing calls from a fixed generator with a target hash after each call | yes |
| ddnr | Lua | Differential drawing without drawRotated (random calls, target hash after each) | yes |
| ddnr2 | Lua | Differential drawing without drawRotated (random calls, target hash after each) | yes |
| ddnr3 | Lua | Differential drawing without drawRotated (random calls, target hash after each) | yes |
| ddrep | Lua | Single drawing calls from the drawdiff probe that differed between the Simulator and an emulator | yes |
| ddrep2 | Lua | Differential drawing: random drawing calls from a fixed generator with a target hash after each call | yes |
| deepcopy | Lua | table.deepcopy on tables holding images and geometry, and the original image after the copy is collected | no |
| deeprec | Lua | Deep Lua recursion that returns normally (no C calls in between) | no |
| dirtyb | Lua | The dirty rect each kind of direct draw produces, read from the background callback's rect | yes |
| dirtyq | Lua | Which dirty rects merge (background callback calls per frame, with their rects) | yes |
| dispimg | Lua | Which frame getDisplayImage returns during update, with and without sprites, before and after drawing | yes |
| dispinv | Lua | Does playdate.display.setInverted change getDisplayImage / getWorkingImage contents? | yes |
| disppl | Lua | Does getDisplayImage always return the previous frame? | yes |
| dithdef | Lua | The default type of setDitherPattern(alpha), compared with each explicit type, at several alphas | yes |
| dlistq | Lua | listFiles order in the data folder for files made at run time, and after deleting and re-adding | yes |
| drawargs | Lua | The rect passed to a Lua sprite draw callback, for fractional positions and partial redraws | yes |
| drawdiff | Lua | Differential drawing: random drawing calls from a fixed generator with a target hash after each call | yes |
| drawdiff2 | Lua | Differential drawing: random drawing calls from a fixed generator with a target hash after each call | yes |
| drawfps | Lua | playdate.drawFPS boxes at several refresh rates and positions (glyphs and digit spacing) | yes |
| drawfps2 | Lua | drawFPS under a draw offset, a clip rect, an image draw mode, inside an image context; single-digit rates | yes |
| ds2 | Lua | image:drawSampled with random centers, matrices, offsets, z, tilt and tiling | yes |
| dsimg | Lua | Where datastore.writeImage puts images, and what readImage reads back | yes |
| dtw | Lua | The width gfx.drawText returns against getTextSize, for single characters and short strings, in the system font (three styles) and a Bitmore font | yes |
| dtw2 | Lua | The size gfx.drawText returns when the first glyphs have no ink or start right of the origin | yes |
| dwt | Lua | drawWithTransform against drawSampled with equivalent parameters | yes |
| edges | Lua | fillPolygon edge rules on small triangles and polygons (pixel dumps) | yes |
| effq | C | A custom effect's process callback: the arguments it receives and stack alignment at the call | no |
| ell14 | Lua | Ellipses with a 14-pixel axis (fills and outlines), and circles 13..15 at several positions | yes |
| ellf | Lua | Wide ellipse outlines over widths, sizes (odd, even, non-square) and stroke locations | yes |
| ellfrac | Lua | fillEllipseInRect / fillCircleAtPoint / drawCircleAtPoint with fractional positions and sizes, and fractional round rects | yes |
| ellfrac2 | Lua | One ellipse rect given as integers and as fractions that round to it | yes |
| ellint | Lua | Integer fillEllipseInRect over circle sizes 1..28 and 60 random ellipses (32x32 target) | yes |
| ellw | Lua | Wide ellipse outlines over widths, sizes (odd, even, non-square) and stroke locations | yes |
| enumq | C | API outputs of enum type are one byte on the device (guard bytes stay untouched) | no |
| epochq | Lua | epochFromTime and epochFromGMTTime with unusual dates, and timeFromEpoch edge cases | yes |
| errpos | Lua | Whether errors raised by API functions carry the calling Lua line | yes |
| f32q | Lua | Are geometry fields single precision? | yes |
| f7 | Lua | multi-frame scenes inside playdate.update (sprites, drawing, display), capturing each completed frame | yes |
| fadeargs | Lua | drawFaded and fadedImage argument checks, and drawFaded's flip forms | yes |
| fadediff | Lua | drawFaded and fadedImage across every dither type, with clipping, offsets, flips and odd alphas | yes |
| fadeds | Lua | fadedImage of a solid black 16x16 image for each ordered dither type at several alphas | yes |
| fadeneg | Lua | drawFaded's dither phase at negative positions | yes |
| fadenone | Lua | drawFaded and fadedImage with kDitherTypeNone near alpha 0.5, and the other types at a few alphas | yes |
| fadeph | Lua | drawFaded pattern phase for a trimmed and an opaque image at negative and positive positions | yes |
| fadetab | Lua | per-cell fadedImage thresholds for the ordered dither types, alpha k/255 for k = 0..256 | yes |
| fadetype | Lua | drawFaded and fadedImage with dither types outside 0 to 10 | yes |
| fadetype2 | Lua | An unknown dither type in drawFaded at several x and y positions, and with a draw offset | yes |
| famq | Lua | setFontFamily given a font instead of a table, and getFont variants | yes |
| farq | Lua | Overlaps and queries of sprites far from the origin (cells past 32767 and below -32768) | yes |
| ffam | Lua | The font family argument of drawText and drawTextInRect, with missing variants, styled text, and the returned size | yes |
| fffdq | Lua | getTextSize and drawText widths around the replacement glyph U+FFFD in styled system text | yes |
| fffdq2 | Lua | The italic system font's replacement glyph U+FFFD measured through font methods | yes |
| fffdq3 | Lua | Widths of strings ending in an empty glyph (the italic system font's U+FFFD), via getTextWidth | yes |
| filerun | Lua | playdate.file.run on a Lua file that returns a table | no |
| firstupd | Lua | In which frame things set up in the main chunk first run (sprite update, timers, frame timers, redraw sprites) | yes |
| flimq | Lua | How many files can be open at once, the error for one more, and whether closing frees a slot | yes |
| fline | Lua | 1-pixel lines with fractional end points, drawn into 48x48 images | yes |
| fline2 | Lua | Every integer line from (13, 13) to (13 + dx, 13 + dy), \|dx\|, \|dy\| <= 12, both orders | yes |
| fmaq | C | Fused multiply-add and float maths (a*b+c both ways, sinf, cosf, atan2f, sqrtf) on random inputs | no |
| fmtq | C | printf-style formatting through the C API, compared with the host's snprintf (cases.h) | yes |
| fontdt | Lua | What font:drawText returns, beside gfx.drawText | yes |
| fontgc | Lua | Whether fonts made and dropped every frame are freed | no |
| fontload | Lua | per-character widths of a bundled font and of the system fonts | no |
| fontreset | Lua | Which graphics state set in the main chunk survives into the first updates | yes |
| fpnone | Lua | A file player with no file: play, isPlaying over frames, load while "playing", stop, callbacks | yes |
| fpq | Lua | Fileplayer and sample results without a file, and sample defaults | yes |
| fpsfont | Lua | Which system font draws the FPS digits ("30" at 1,1, black on white) | no |
| fracargs | Lua | How integer-taking calls treat fractional arguments (truncate, round, floor, or error) | yes |
| fracq | Lua | Where images land at fractional positions, for draw, drawIgnoringOffset, drawCentered, drawAnchored, drawScaled and sprites | yes |
| ftq | Lua | Frame timers (deterministic): values, callbacks, repeats, reverses, delays, pause and removal | yes |
| geoflt | Lua | Number types of geometry fields after construction with integers and after assigning integers | yes |
| glyphfb | Lua | Drawing button glyphs (U+24B6, U+24B7) with the system font and with a font that lacks them | yes |
| glyphq | Lua | Which code points the text drawer skips (no glyph, no advance) | yes |
| glyphq2 | Lua | drawText's returned size and pixels with missing and skipped code points | yes |
| glyphq3 | Lua | font:getGlyph with multibyte characters, missing characters, numbers and odd arguments | no |
| glyphq4 | Lua | font:getGlyph with numbers - code point or the number's text? | yes |
| groupq | Lua | How group masks decide overlaps and collisions (group 0, nonzero groups, collides-with masks) | yes |
| heapaddr | Lua | Address order and gaps of freshly made Lua tables | no |
| hook | Lua | Can a game replace playdate.graphics functions? | yes |
| hugeline | Lua | Do drawing calls with huge coordinates take time proportional to the coordinates? | no |
| identq | Lua | Whether getters return the same Lua value each time (rawequal and ==) for images, tables, fonts | yes |
| imgfrac | Lua | image.new with fractional and negative sizes | yes |
| importq | Lua | Whether a second import of the same file runs it again, from main and from another file | yes |
| importret | Lua | What import returns for a module, and a second import of the same file | no |
| inp | Lua | Input queries each frame and every input callback (buttons, crank) under a scripted timeline | no |
| invq | Lua | The inverted flag (setInverted) through copy, invertedImage, drawing, sampling and derived images | yes |
| itlen | Lua | Imagetable length and indexing | yes |
| jsondec | Lua | json.decode edge cases | yes |
| jsonenc | Lua | json.encode and json.encodePretty edge cases | yes |
| jsonexp | Lua | How json.decode rounds numbers with exponents: 4,730 numbers (fractions, exponents -47 to +40, subnormals, overflow, wrapped exponents) as exact float bits | yes |
| jsonfmt | Lua | json.encode number and string formatting, encodePretty, decode types, and edge cases | yes |
| jsonord | Lua | Key order of json.encode and pairs for small string-keyed tables | yes |
| jsonsmall | Lua | json.decodeFile on files of 0 to 5 bytes (with and without a byte order mark), by path and by open file, next to json.decode | yes |
| kbq | Lua | The CoreLibs keyboard, shown and dumped as a character grid after its show animation | yes |
| keys | Lua | Button state, crank position and docking over time under scripted Simulator input | no |
| lf | Lua | lockFocus drawing into an image and whether the screen is touched | no |
| linebig | Lua | Lines starting above the clip top with extreme coordinates | no |
| lineclip | Lua | Lines with ends off the target or outside the clip rect (pixel lists) | yes |
| linewid | Lua | drawLine with an explicit width argument (0, negative, fractional, nil) and after a lineSegment; 1-pixel lines entering the clip rect from above inside and outside its x range | yes |
| listf | Lua | playdate.file.listFiles on compiled bundle folders (names, extensions, order, trailing slashes) | yes |
| lmathq | Lua | Exact bits of Lua math results over fixed inputs (which libm the runtime uses) | yes |
| locq | Lua | getLocalizedText with .strings files, languages, missing keys and odd arguments, and localized text drawing | yes |
| locqu | Lua | getLocalizedText with .strings files: locq under a second bundle ID, built with `pdc -u` (uncompressed tables) | yes |
| luac | C + Lua | The Lua C API from a hybrid Lua/C game: addFunction, registerClass, argument and return handling | yes |
| luacap | C + Lua | A MIDI sequence on an instrument with no channel added, captured through a C capture effect | no |
| luacap2 | C + Lua | Lua synth, sample player, delay line, bitcrusher and file player timing and callbacks, captured through a C capture effect | yes |
| luacap3 | C + Lua | Lua instrument shortcuts (playNote, playMIDINote, noteOff), captured through a C capture effect | yes |
| luacap4 | C + Lua | Lua LFO API (arpeggio, delay, retrigger, random seed), notes on the audio clock, captured through a C capture effect | no |
| luaenvg | C + Lua | Lua envelope:setGlobal and synth:setEnvelopeCurvature, captured through a C capture effect | no |
| luafade | C + Lua | File player volume fades (Lua setVolume with fade time and callback), captured through a C capture effect | no |
| luafp | Lua | Lua file player behavior (play defaults, loop ranges and callbacks, stop, pause, offsets, buffer size) | yes |
| luafp2 | Lua | File player seeks while playing and while stopped, and offsets right after | yes |
| luamem | Lua | Lua memory use of numbers, small records and string-keyed maps (collectgarbage count) | no |
| luasp | C + Lua | Lua sample player (play ranges, loops, reverse, ping-pong, playAt, callbacks, offsets, rates), captured through a C capture effect | no |
| luaval | Lua | Argument validation: API calls with odd arguments (each case prints ok or error) | no |
| markq | Lua | Nested *bold* and _italic_ markup, with and without an italic font in the family | yes |
| menuq | Lua | The system menu API: item limits, errors, titles, values, options, removal | yes |
| metaq | Lua | The keys, types and values of playdate.metadata, and getHeadphoneState's results | yes |
| midc | C | sample-synth playback steps at chosen frequencies (the middle-C pitch constant) | yes (raw capture) |
| midi | Lua | Two MIDI files loaded as sequences: tempo, length, tracks and notes | yes |
| midi3 | Lua | A format 1 MIDI file with overlapping and unmatched notes, controllers, pitch bend range and bends | yes |
| modeq | C + Lua | Whether the C API's draw mode is the same state as Lua's image draw mode | no |
| mtgc | Lua | Where native objects' finalizers live (the class metatable's __gc) and whether metatables are protected | yes |
| mtleak | Lua | Swapped metatables on native objects - leaks, and another type's __gc on an object | no |
| negclip | Lua | Mirrored scales of images whose stored data is trimmed | yes |
| negscale | Lua | scaledImage and drawScaled with negative scales (size and pixels) | yes |
| netq | Lua | Network, server time, launcher and other system functions without network permission | yes |
| newidx | Lua | Setting and reading unknown fields on menu items, pathfinder nodes and graphs, and other native objects | yes |
| nineq | Lua | nineSlice drawing at many sizes, imageWithText, and drawTextInRect truncation and alignment | yes |
| numtype | Lua | Integer or float, for the numbers that argument-free getters return | yes |
| objmodel | Lua | Type, metatable and field behaviour of each native object class (sprite, image, font, geometry, sound) | yes |
| occl | Lua | Whether sprites covered by an opaque sprite still draw (draw callbacks logged per frame) | yes |
| occl2 | Lua | Whether a moved sprite's new dirty rect is cut by an opaque sprite above it (callbacks log their rects) | yes |
| occl3 | Lua | Does a hidden or removed opaque sprite still cut the dirty rects of sprites moving under it? | yes |
| opq | Lua | Sprite opaque flag after setImage with images with and without masks, and image.new mask presence | yes |
| overlapq | Lua | allOverlappingSprites and overlappingSprites, before and after a sprite update | yes |
| pat | Lua | setPattern rows: which bits of an 8-byte pattern fill which pixels | no |
| pat2 | Lua | setPattern phase: 24x24 pattern fills in an image and on screen | yes |
| pat3 | Lua | setPattern phase: one row takes every value 0..255, the others all 0xFF or 0x00 | yes |
| pat4 | Lua | setPattern phase with explicit x, y arguments, and with 16-entry (pattern + mask) tables | yes |
| pat6 | Lua | setPattern argument edge cases (image with x only, image with x and y, eight integers, short tables) | yes |
| pat7 | Lua | setPattern(image, x, y) on a 16x16 source (block or phase?), masked patterns over black and over a clear destination, and short tables | yes |
| pathq | Lua | Pathfinder graphs; paths with and without heuristics, adjacent-goal searches, weights, ids | yes |
| paths | Lua | Imagetable getImage identity and indexing, and a tilemap using the table | no |
| patq | Lua | setPattern rows (0x55 drawn as 0xAA in the Simulator) | yes |
| perfloop | Lua | A heavy update loop (many image draws and drawText calls) for timing | no |
| perfq | Lua | Cost of common calls (milliseconds for many iterations) | yes |
| pies | Lua | Filled and outlined ellipse arcs (pies) on small images (pixel dumps) | yes |
| poly2 | Lua | fillPolygon on random 4..10-vertex polygons (self-intersecting, repeated points), both fill rules, clip and offset | yes |
| polyfill | Lua | fillPolygon on a fixed set of small random triangles and polygons (pixel dumps) | yes |
| polyh | Lua | fillPolygon on random polygons with 3 to 6 vertices (sorted angles around the center, random radii; integer and fractional points), 40x40 target | yes |
| polyopen | Lua | Open polygons through drawPolygon, fillPolygon, transforms and copies | yes |
| polyq | Lua | fillPolygon on random convex quadrilaterals (integer and fractional points), 40x40 target | yes |
| polys | Lua | fillPolygon on a fixed set of small random polygons (pixel dumps) | yes |
| powq | Lua | Power status and battery readings | yes |
| preimp | Lua | What exists before the CoreLibs imports, early overrides, and geometry-object forms of CoreLibs functions | yes |
| q8 | Lua | Native API cases for patterns, contexts, text, ellipses, lines, rotation, scaling, tilemaps and sprites | yes |
| qorder | Lua | The order of sprite query results (point, rect, line, overlapping) with many overlapping sprites | yes |
| qorder2 | Lua | Sprite query and overlap order when the collision cell table grows and shrinks, after moves and removals | yes |
| randq | Lua | math.random's sequence without math.randomseed | yes |
| rayq | Lua | querySpriteInfoAlongLine and querySpritesAlongLine over random segments, exact values | yes |
| rectq | Lua | Fields of geometry objects (aliases such as w and h) | yes |
| rectsm | Lua | drawRect with small sizes and line widths (pixel lists) | yes |
| reqq | Lua | Every key of _G and of the standard library tables | yes |
| restq | Lua | playdate.restart(args): does the game start again, what argv it gets, and when the restart happens | no |
| retq | Lua | How many values, and of which types, common API calls return (setters included) | yes |
| retq2 | Lua | Values behind the return-count differences found by retq | yes |
| retq3 | Lua | Return counts and types for sound, timers, animators, geometry operators and string helpers | yes |
| ring | Lua | An orbit ring (white fill, then a wide dithered circle outline), and variants | yes |
| rot0frac | Lua | drawRotated (angles 0, 90, 180, 360) and drawCentered at fractional centers; left/top edge of the result | yes |
| rot0m | Lua | rotatedImage of trimmed images at 0, 90, 180 degrees and small angles: sizes, masks and the last column | yes |
| rot3 | Lua | rotatedImage and drawRotated on random images (with transparency) at random angles and scales | yes |
| rotbig | Lua | huge-scale rotated drawing (only the visible part is sampled); a row hash per case | no |
| rotc | Lua | Rotated sprites with off-middle centers: bounds and drawn pixels | yes |
| rotc2 | Lua | Which drawing method reproduces a rotated sprite's pixels? | yes |
| rotctr | C | drawRotatedBitmap with off-centre centers at scales above and below 4 megapixels, and a scale of 1e30 | yes |
| rotimg | Lua | image:rotatedImage(angle) sizes and pixels for several images and angles | yes |
| rotimg2 | Lua | rotatedImage on random images and angles; the sources are dumped too | yes |
| rotopq | Lua | A sprite's opaque flag after rotation and scaling | yes |
| rotscl | Lua | drawRotated with angle 0 and a scale, and nearby cases | yes |
| rotsz | Lua | rotatedImage sizes over a grid of angles and scales, two source sizes | yes |
| rotxy | Lua | full-frame dumps of a trimmed image drawn scaled with different x and y scales | yes |
| rr2 | Lua | Round rects over radii 0..20, line widths 0..9, stroke locations, sizes 1..44, random positions | yes |
| rr_const | Lua | Every k* constant under playdate (case suite 5) | yes |
| rr_core | Lua | Native API cases: constants, primitives, graphics state, images, text, sprites, files, JSON, time, sound objects (case suite 3) | yes |
| rr_cov | Lua | Coverage cases for functions not reached by the other suites (case suite 4) | yes |
| rr_geo | Lua | Geometry objects (rect, point, vector2D, size, lineSegment, arc, polygon, affineTransform) and CoreLibs table helpers (case suites 1 and 2) | yes |
| rr_upd | Lua | update-loop and video functions (case suite 6) | yes |
| rrq | Lua | Display refresh rate values read back after setRefreshRate | yes |
| rrsmall | Lua | fillRoundRect / drawRoundRect with radius 0 and 1 across widths and heights (corner cutting) | yes |
| runaway | Lua | Game code that never returns (a loop that pcall keeps restarting); the runtime must still stop | no |
| samp | Lua | image:sample with integer and fractional coordinates, inside and outside | yes |
| sc2 | Lua | drawScaled and scaledImage with fractional and negative scales, random images with transparency | yes |
| scale2q | Lua | The display image and clearing at display scale 2 | yes |
| scaleq | Lua | Downscaled drawing (drawRotated with angle 0 and a scale, drawScaled) of a patterned image | yes |
| scanq | C | parseString with scanf-only syntax (suppressed assignments, sets), logged | no |
| sclclip | Lua | Scaled and rotated drawing of images whose stored data is trimmed (transparent edges) | yes |
| sclip | Lua | Sprite clip rects away from the origin, with centers, offsets, and ratios | yes |
| sclip2 | Lua | per-frame clip rect updates on a sprite, combined with visibility changes | yes |
| sclip3 | Lua | How fractional sprite clip rects round (x, y, width, height) | yes |
| scoreb | Lua | playdate.scoreboards offline: the functions present, what they return, and when their callbacks run | yes |
| seqpos | Lua | Sequence position (goToStep, getCurrentStep) and finish callbacks around play and stop | yes |
| setmt | Lua | Whether setmetatable and getmetatable work on userdata | yes |
| shareq | Lua | Whether images given to or taken from containers share pixels with the original after later drawing | yes |
| sigval | Lua | The class of a channel's level signals (playdate.sound.signalvalue) and what it can do | yes |
| sinetab | C | ring modulator at every phase, sine LFO values, sample-and-hold LFO sequence | yes (binary dumps) |
| snd | Lua | Loading a WAV file as a sample | no |
| spm | Lua | The names of every function in playdate.graphics.sprite | yes |
| spradd | Lua | Sprites added or removed during sprite.update, and the update order | yes |
| spradddraw | Lua | A sprite's draw callback removes and re-adds another sprite; frame hashes | yes |
| sprbgq | Lua | Sprites over a background drawing callback that sets and clears the clip rect; frame hash per step | yes |
| sprclr | Lua | The area a sprite update clears (background) for sprites at fractional bounds | yes |
| sprdfrac | Lua | Sprites that grow by fractional sizes and move by fractional steps each frame; every display frame dumped | yes |
| sprdiff | Lua | Differential sprite and collision operations on random scenes, logging every result | yes |
| sprdiff2 | Lua | Differential sprite and collision operations on random scenes, logging every result (with detail) | yes |
| sprdirty | C | Sprite->markDirtyRect (SDK 3.1) | yes |
| sprflipscl | Lua | Sprites drawn with both a flip and a scale (via setImage and setScale), at whole and half positions | yes |
| sprimg | Lua | A sprite whose image changes between frames of the same imagetable | yes |
| sprimgpart | Lua | An image changed during the update while another moving sprite forces a partial redraw of it | yes |
| sprimgupd | Lua | A sprite's image drawn into at different points of the frame; the next frame reads back what the display shows | yes |
| sprmode | Lua | When a sprite's image draw mode change reaches the screen (a hit flash) | yes |
| sprmove | Lua | Sprites moving by fractional steps over a background; display rows hashed every frame | yes |
| sprre | Lua | sprite.update called again from inside the background drawing callback and a sprite's draw | yes |
| sprrot | Lua | Rotated sprites' size, bounds and the area they draw and clear | no |
| sprrotq | Lua | Sprites with rotation drawn by sprite.update; per-frame pixel hash of the frame | yes |
| sprscale | Lua | Sprite size, bounds and drawn place with a scale | yes |
| sprscq | Lua | Scaled sprite images (setImage, setScale) at fractional positions, partly off screen; drawn area | yes |
| sprsizeq | Lua | Sprites with fractional sizes and positions; their bounds and the area their draw callback covers | yes |
| sprupq | Lua | sprite:update() on an instance (no override) versus gfx.sprite.update(); super.update from a subclass | yes |
| srcflip | Lua | image:draw with a source rect that runs past the image, under every flip, on white and black | yes |
| srcrect | Lua | Fractional source rects in image:draw (rect object and numbers), and fractional draw positions | yes |
| stackq | Lua | Deep recursion through native calls must raise a Lua error, never overflow the host stack | yes |
| stale | Lua | Does text drawn straight to the frame survive sprite.update once the game stops drawing it? | yes |
| stale2 | Lua | Which rects does sprite.update redraw after drawing straight to the frame? | yes |
| stale3 | Lua | Dirty rects of images with transparent margins (trimmed by pdc), plain and flipped, and of text | yes |
| stale4 | Lua | When sprite.update redraws direct draws (sprites present, background color, history) | yes |
| stencil | Lua | Stencil semantics for fills, images and sprites | yes |
| stillopen | Lua | Wide rounded rects, random triangles and polygons, odd-sized and centered-stroke ellipses, drawSampled tilt, and the collision world after removeAll | yes |
| stpat | Lua | gfx.setStencilPattern(level, ditherType) for every dither type and levels 0 to 1 by 0.01; the 8x8 stencil read back by filling through it | yes |
| stpat2 | Lua | Exact level at which each cell of gfx.setStencilPattern(level, ditherType) turns on (bisection) | yes |
| sty | Lua | Styled text glyph positions (first ink column of each glyph run) | yes |
| syncq | C + Lua | Other state the C API and Lua might share: elapsed-time timer, refresh rate, sprite list, drawn frame, display inversion and scale | yes |
| tim | Lua | When CoreLibs timers and animators fire, by frame and by clock | no |
| timeq | Lua | wall-clock time functions (compare fields; seconds differ between runs) | yes |
| tmdirty | Lua | Does setTileAtPosition on a sprite's tilemap redraw the sprite without markDirty? | yes |
| tmoccl | Lua | Tilemap sprites hiding sprites below (whole dirty rects, and new bounds cut to the clear tiles) | yes |
| tmoffq | Lua | Tilemap and image drawIgnoringOffset under a draw offset, in an image context and on screen | yes |
| tmunset | Lua | Tilemap tiles that were never set, out-of-range positions, and getTiles | yes |
| tmupd | Lua | Tilemap tiles changed during a sprite update, with and without another sprite forcing partial redraws | yes |
| touchq | Lua | Collision points (touch, slide, bounce) and rects for off-centre sprites and offset collide rects | yes |
| tri | Lua | Random filled triangles, including flat and degenerate ones | yes |
| trim2 | Lua | Other drawing paths with images whose stored data is trimmed | no |
| triq | Lua | drawTriangle with vertices off the target | yes |
| trsz | Lua | transformedImage sizes and pixels | yes |
| tw | Lua | getTextSize widths of short strings with *bold* and _italic_ markup | no |
| twrap | Lua | drawText with a width and height: default wrap mode, explicit modes, alignment, and the returned size | yes |
| txtmode | Lua | drawText in each image draw mode with a bordered bitmap font and the system font, over black and white | yes |
| txtmode2 | Lua | Black screen, Inverted draw mode, a bordered bitmap font with tracking -1 and 0; pixels as text | yes |
| updord | Lua | The order of sprite:update() calls with z indices, sprites added during the pass, z changes, removal | yes |
| updq | C + Lua | A C update callback set in kEventInitLua in a game with a Lua playdate.update: which run, and in what order | no |
| uvcount | Lua | The userval_count field of every class table reachable from playdate | yes |
| vcr | Lua | vcrPauseFilterImage on larger images, consecutive calls (global LFSR) | yes |
| vcr2 | Lua | 40 consecutive vcrPauseFilterImage calls on a full-screen pattern | yes (out.txt.gz) |
| vidcf | Lua | video:getCurrentFrame after renderFrame calls | yes |
| voiceq | Lua | When instrument:addVoice refuses a synth | yes |
| wide | Lua | Random wide lines (widths 2 to 8) with butt, square, and round caps | yes |
| wlines | Lua | Wide lines with each cap style on a fixed set of random segments (pixel dumps) | yes |
| xf | Lua | drawWithTransform / transformedImage with rotations, scales, skews and translations of a small image | yes |
| xorline | Lua | drawLine with kColorXOR over black and white, various slopes; also XOR fillRect and drawRect | yes |
| zeroline | Lua | zero-length lines (both end points equal) at widths 1 to 6 with each cap style, and XOR | yes |
