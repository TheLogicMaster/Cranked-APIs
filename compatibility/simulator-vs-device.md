# Simulator Versus Device

This file lists where the Playdate Simulator from SDK 3.1.1 (the Linux build, run headless) and the device (OS 3.1.2, by
analysis) behave differently, and which of the two an emulator should follow. Most of the API behaves the same in both,
and the topic files describe that shared behaviour; this file collects only the differences and the open cases. The
differences come from four sources: things only one environment has, the Simulator being a native x86 program (its
numeric conversions and maths results differ from the device's), the host's file system and memory, and bugs that
crash one environment. For games that are affected, see [games.md](games.md).

## Which One to Follow

**The device is the reference.** A game is made to run on a Playdate; where the two differ, the device's behaviour is
what players see. The Simulator is still the best oracle that can be run automatically, so:

- Follow the device wherever its behaviour is known.
- Where only the Simulator has been measured, follow the Simulator, and treat the result as provisional until it is
  checked on hardware. Items below marked **check on hardware** are of this kind, or are cases where the two are
  expected to differ but the device's result is not known.
- Do not copy Simulator crashes, hangs or host artefacts (64-bit addresses, case-sensitive names, x86 conversion
  results).
- An emulator may offer a Simulator mode (setting `playdate.isSimulator`, providing `playdate.simulator.*`, rounding as
  x86 does) for comparing against Simulator captures, but the default should be the device.

The probes named below are in [tests/probes](../tests/probes/); see [tests/tools](../tests/tools/) for running them in
both environments.

## Things Only One Environment Has

| Item | Simulator (SDK 3.1.1) | On the device (3.1.2, by analysis) | Follow |
| --- | --- | --- | --- |
| `playdate.isSimulator` | 1 | nil | Device: leave it nil. Games branch on it (celeste draws 16 clouds when it is set, 4 when it is nil) |
| `playdate.simulator.*` (`writeToFile`, `exit`, `getURL`, `openURL`), C `getDebugBitmap` | Present | Absent (the C pointer is NULL) | Device |
| `playdate.debugDraw` | Supported (the Simulator's debug layer) | Absent | Device: nil until the game defines it, and never called |
| C `kEventKeyPressed` / `kEventKeyReleased`, Lua `keyPressed` / `keyReleased` | Sent for the computer's keyboard keys | Never sent | Device |
| `playdate.getStats()` | nil | Not measured (documented to return a table) | Return a table; **check on hardware** |
| `getHeadphoneState` | Lua: (true, false) on Linux; C leaves its outputs untouched | Real headphone state | Report no headphones unless the host knows better |
| `getPowerStatus()` | Charging, on USB, 100%, 4.2 V | Real battery state | Report charging over USB, as the Simulator does. Games such as cloudburst take a 5 fps low-power path on battery, so a battery emulation changes game behaviour. **Check on hardware** both on the cable and on battery |
| Network access | Shows "Allow Internet Access?" on the first `http.new`, `https.new`, `tcp.new` or `requestAccess`; `network.getStatus()` is 2 (not available) | The same permission check: C `http->newConnection` returns NULL without access, `tcp->open` returns -20 | Without a prompt, decline: `new` returns nil, `requestAccess` false (C `kAccessDenied`) |
| Serial messages, Mirror | Not used | `serialMessageReceived`, `mirrorStarted`, `mirrorEnded` | Never called by an emulator without those connections; `sendMirrorData` returns false |

## Floating Point and Integer Conversion

The Simulator is a native x86-64 program; the device is an ARM Cortex-M7. Three kinds of difference follow.

**Float-to-integer conversion out of range.** x86 gives its overflow value (0x80000000) or wraps a negative value to
a large unsigned one; ARM saturates (to 0x7FFFFFFF, or to 0 for a negative value converted to unsigned).

| Case | Simulator | On the device (3.1.2, by analysis) |
| --- | --- | --- |
| Square wave duty cycle of 0.5 or more (`setParameter(1, d)` or a modulator) | Stored as 0x80000000 | Saturates at 0x7FFFFFFF, one phase unit lower; a few samples in ten thousand differ in the last bit |
| Ring modulator driven below 0 Hz by a frequency modulator | The phase steps backward | The step saturates at 0, so the phase holds |
| File player at a negative rate | The step wraps to a large unsigned value | The step is 0: the player holds its frame |
| Zero-length wide line (both end points equal, width 2 or more) | Only the caps are drawn (measured, `tests/probes/zeroline`) | Only the caps are drawn (nothing with butt or square caps); guard the zero length: computing the quad from it gives huge corners that dirty the whole screen |

**Fused multiply-add.** On the device (3.1.2, by analysis) these computations round once (fused multiply-add); the
x86 build rounds twice. This changes the last bit of some results, and through a threshold, whole pixels or samples:
- LFO values (center + value x depth) on the device are one fused operation; through a square wave's duty cycle a few
  samples change (`tests/probes/audwtab2`).
- A delay-line tap's modulated delay (44100 x value added to the set delay) is fused on the device (3.1.2, by
  analysis).
- `drawSampled` (the row depth, the row start and the u and v sums) and `drawWithTransform` use fused operations on the
  device (3.1.2, by analysis). On the SDK example drawSampled2, the Simulator samples a neighbouring source row on whole
  rows where a source row boundary falls (about every 33 rows); **check on hardware** (`tests/probes/ds2`).
- **C games** compiled for both environments diverge the same way, and also through the C library (the device's `sinf`,
  `cosf`, `atan2f` against the host's). Physics that calls these every frame (Spaceshipment) drifts apart after hundreds
  of frames. An emulator running the game's ARM code reproduces the device; compare C float results with the device,
  not with the Simulator (`tests/probes/fmaq`). **Check on hardware** whether the device sets flush-to-zero or
  default-NaN modes.
- Two compilers also evaluate function arguments in different orders, so a C game that calls `rand()` several times
  inside one call's arguments gets different values in the Simulator.

**Undefined behaviour.**

| Case | Simulator | On the device (3.1.2, by analysis) |
| --- | --- | --- |
| `font:getGlyph(s)` with a first byte from 0x80 | Reads the byte as a signed index: "\uFFFD" gives an unrelated image, "\u00E9" crashes | Decodes the first UTF-8 character (a bad continuation byte gives 0) |
| `vcrPauseFilterImage` where the random offset is negative | Copies bit (x + offset) & 7 of the row's first byte | Those pixels stay black. **Check on hardware** (`tests/probes/vcr`) |
| A file player with a sine LFO as its rate modulator | Stops with SIGFPE in the first block | The player plays at the LFO's value, one value per block. **Check on hardware** |
| `imagetable:getSize()` on a table with no columns | | The row count is 0 |
| Signed integer overflow at coordinates near 2^31 | | Wraps. Compile an emulator's core with wrapping signed arithmetic (for example `-fwrapv`) |
| C `scanf`-style parsing (`parseString`) of out-of-range integers | Wraps | Saturates |
| JSON integer out of range after a wrapped exponent (`-7688231203E020`) | -2147483648 (x86 conversion) | Saturates: 2147483647 ([../data/json.md](../data/json.md)) |

For comparing against Simulator captures, an emulator can offer an option that rounds and converts as x86 does; the
audio probes match the Simulator bit for bit that way.

## Memory and Addresses

| Item | Simulator | On the device (3.1.2, by analysis) | Follow |
| --- | --- | --- | --- |
| `tostring` of tables, functions, userdata; `string.format("%p")` | 64-bit host addresses (`table: 0x555fdf186ac0`) | 32-bit addresses, printed as `0x` and unpadded lowercase hex | Device; **check on hardware** (`tests/probes/heapaddr`) |
| Lua memory use | Lua values are 64-bit on the host, about twice the device's size; the Simulator has more memory | 16 MB shared by Lua and everything else | Device limits where possible. On a 64-bit host, giving Lua a separate region avoids running out where the device would not |
| Allocation failure (`sample.new` larger than the heap) | Succeeds (more memory) | Fails | Return nil, as for a negative length; **check on hardware** |
| `pairs` order over object-keyed tables | Follows host addresses (repeatable for a given game) | Follows memory addresses | Not stable (depends on memory addresses) and cannot be reproduced exactly; **check on hardware** whether it is deterministic |
| `pairs` order over string keys, plain `json.encode` key order | Changes from run to run (per-run hash seed) | Changes from boot to boot (on the device (3.1.2, by analysis)) | Either; offer a fixed seed for repeatable tests. **Check on hardware** whether the device's seed is in fact fixed (`tests/probes/jsonord`) |
| `allOverlappingSprites` outer order | Follows memory addresses | Follows memory addresses (sprite addresses) | Not stable (depends on memory addresses) and cannot be reproduced exactly; any consistent order |
| C bitmap from `newBitmapTable(count, w, h)` before `setTableBitmap` | Cells report 65535 by 65535 | Every cell is 65535 by 65535 with a row stride of 0 | An emulator may keep real sizes: the device result depends on unrelated memory, and games that work fill the table first |
| The display buffer's row padding before the first frame | Reads 0 | | Unimportant; reads 0 |

## Lua Runtime

| Item | Simulator | On the device (3.1.2, by analysis) | Follow |
| --- | --- | --- | --- |
| C-call depth | "C stack overflow" at depth 199 (`tests/probes/stackq`) | About 200 levels | 199 is what has been measured; **check on hardware** |
| Lua API argument-check failures (bad stack index, upvalue past 256) | Shows the checked expression | The check's message, as "%s at %s:%d" | Device |
| A game update that never returns | The Simulator stays responsive | The device hangs | An emulator must still be able to stop it |

The Lua language itself (5.4 with 32-bit integers and single-precision floats, and the subset of the standard
library) is the same in the Simulator and on the device (3.1.2, by analysis).

## Files

| Item | Simulator (Linux) | On the device (3.1.2, by analysis) | Follow |
| --- | --- | --- | --- |
| Letter case in file names | Case-sensitive: `font.new("fonts/monocraft-18")` for `Monocraft-18.fnt` fails | The data disk is FAT, which ignores case; the load succeeds | Device: when no file has the exact name, accept one that matches ignoring ASCII case. The macOS and Windows Simulators also ignore case |
| `getSize` of a directory | 4096 (the host's block size) | | 0 is acceptable; no game was seen to depend on it |
| Data folder | `Disk/Data/<bundleID>/` | `/Data/<bundleID>/` on the data partition | Either; an empty `bundleID` uses the bundle's name |

## Clocks and Speed

- **CPU speed.** The device is much slower than any desktop. Frame times, `getElapsedTime` around work, and
  `getFPS`/`drawFPS` readouts differ, and games that print their measured frame rate differ in that text. An emulator
  does not need to model the device's timing to run games correctly; it must keep frame pacing at the requested rate.
- **Audio clock.** Run headless with no audio device, the Simulator's audio engine never runs: `getCurrentTime` stays
  0 and sounds never finish. With an audio device, its audio starts about 7,168 samples before the first update and
  advances in 1,024-sample host buffers. On the device (3.1.2, by analysis) it advances one block per 256 output
  frames. Follow the device: advance the clock at 44.1 kHz.
- **Server time.** Without a network, `getServerTime` calls back at the next update with nil and "Internal Error: -20"
  in the Simulator, and C `system->getServerTime` does the same.

## Crashes and Hangs in the Simulator

These crash or hang the 3.1.1 Linux Simulator. Probes avoid them. The device may be affected too, but an emulator
should not crash in any of them.

| Case | Simulator | On the device (3.1.2, by analysis) |
| --- | --- | --- |
| `json.encode` of a table after an encode or decode error inside a nested table (for example `encodePretty({[true] = 1})`) | The next table encode can crash | Likely affected. **Check on hardware** |
| A global envelope (`envelope:setGlobal(true)`) used as a synth's modulator | Heap corruption ("smallbin double linked list corrupted") | Likely affected; global envelopes on their own work. **Check on hardware** |
| C `sprite->allOverlappingSprites` | Crashes | **Check on hardware** |
| `font:getGlyph` for a character a wide font does not contain | Crashes | Returns nil |
| `rect:unionWith` with a rect whose `x` is 2^31 - 1 | Crashes | Unknown |
| `fillPolygon` with an unclosed polygon object | Never returns | Raises "Can't fill an open polygon!" |
| `sound->setOutputsActive` with no audio device | Aborts | Not applicable |
| The next network call after `network->setEnabled` | Aborts | Unknown |

## Rendering Cases Still to Confirm

These are rendering results where the device may differ from the Simulator and no device run has settled it.

| Case | Simulator | Notes | Follow for now |
| --- | --- | --- | --- |
| `drawRotated` / `rotatedImage` at angles other than right angles | Each pixel's source position appears to be computed on its own in single precision | On the device (3.1.2, by analysis) each row's start is converted once to 16.16 fixed point and a truncated fixed-point step is added per pixel. That drifts: in `tests/probes/ddrep` a pixel samples u = 2.0004 instead of 1.9997. Single pixels differ (2 in `ddrep`; 16 in onebit frogger's logo at 0.24 degrees) | Device. **Check on hardware** (`tests/probes/ddrep`, `tests/probes/rot3`) |
| Line dither types at a negative phase (`blurredImage`, `drawBlurred`) | Behaves like thresholds near 0 | On the device (3.1.2, by analysis) the result is undefined (it depends on unrelated memory) | Wrap the index. **Check on hardware** (`tests/probes/blurq3`) |
| `fadedImage` with alpha above 1 | Keeps every opaque pixel | On the device (3.1.2, by analysis) alpha x 255 is converted to a byte, so it may wrap | Simulator. **Check on hardware** (`tests/probes/fadediff`) |
| Direct drawing and dirty rects | Every direct draw's bounds become dirty, only after the first sprite exists; glyph rects extend to the line bottom | Games that rely on leftover drawings depend on it | Simulator. **Check on hardware** (`tests/probes/stale` to `stale4`) |
| `tilemap:drawIgnoringOffset` | Applies the draw offset (unlike `image:drawIgnoringOffset`) | Contradicts the documentation | Simulator. **Check on hardware** (`tests/probes/tmoffq`) |
| Alpha collision with one unmasked image | Reads only the first row of the area in the masked image | On the device (3.1.2, by analysis) the rect check reads only the first row | Device. **Check on hardware** (`tests/probes/alphaq2`) |
| `setDitherPattern(alpha)` with a black drawing colour | Black is inverted too: 0 draws solid black, 1 draws nothing | The documentation says only white is inverted | Simulator. **Check on hardware** |

## Behaviour That Depends on the Game's SDK Version

On the device (3.1.2, by analysis), some behaviour depends on the SDK version the game was built with (`pdxversion` in
its `pdxinfo`): for example the sprite stencil rule (setting a stencil makes a sprite not opaque only for games built
with SDK 3.0.100 or later), the mono channel pan law (games built before SDK 2.6 get the older law), and a compatibility
path in the image sampler for games built before SDK 1.5.0. The SDK 3.1.1 Simulator was only measured with games
built by its own `pdc`, so these older paths are known only from the device. An emulator that runs old games should
apply the same version thresholds.

## Documentation Contradictions

Some Simulator results contradict *Inside Playdate*. They are listed here because an implementer may be tempted to
follow the documentation. In each case the behaviour on the device (3.1.2, by analysis) is the one in the right-hand
column.

| Function | Documentation says | Measured in the Simulator | On the device (3.1.2, by analysis) |
| --- | --- | --- | --- |
| `playdate.display.loadImage(path)` | Works for a 400 x 240 image without transparency | Raises "loaded file properties don't match framebuffer's" | The image header must equal the frame buffer's (52-byte rows); pdc writes 50-byte rows, so a pdc-built image never matches and raises the same error |
| `onepolefilter:setParameter(p)` with p > 0 | High-pass | Passes the input unchanged | Passes the input unchanged |
| Paused players: `isPlaying()` | | A paused file player reports false; a sample player paused right after `play()` reports true | A sample player's play starts at the next audio render and `isPlaying` reports the pending start until then, which pausing does not cancel; once started, a paused sample player reports false |
| `playdate.datastore.write(table, [filename], [pretty-print])` | Pretty-printed only when asked | Pretty-printed unless pretty-print is false; a stored number reads back as nil | |
| `playdate.wait(ms)` inside `update()` | Suspends callbacks | Blocks; time has advanced when it returns | |
| `sample:getLength()` | Two equal values for a loaded sample | A loaded sample reports (length, 0); `sample.new(seconds)` reports (0, seconds) | |
| MIDI tempo changes | | Only the first tempo event of a file is used | Only tempo events at tick 0 count |

Where the right-hand column is empty, only the Simulator has been measured; follow it, and check on hardware.
