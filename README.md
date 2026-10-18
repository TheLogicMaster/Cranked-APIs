# Cranked APIs

How the Playdate APIs actually behave, written down while making the Cranked emulator match the Playdate SDK 3.1.1
Simulator and the device (OS 3.1.2). This is the reference for reimplementing Cranked from scratch: what each API
does, its edge cases and error messages, where the Simulator and the device differ, and what real games depend on.
It is not documentation of Cranked itself. The Proof of Concept build that these notes came from is
[Cranked Proof of Concept](https://github.com/TheLogicMaster/Cranked-PoC) (unsupported).

> **AI-written.** Most of this repository (text, probes, tools) was written by an AI system under the maintainer's
> direction, and nothing in it has been run on a physical Playdate yet. See [NOTICE.md](NOTICE.md).

## How to read it

Every behaviour is marked with where it comes from:

- **"In the Simulator (SDK 3.1.1)"**, or just **"measured"**: measured black-box in the Simulator, usually by a probe
  in `tests/probes/` whose recorded output is in its `expected/` folder.
- **"On the device (3.1.2, by analysis)"**: the device's behaviour as determined by analysis of its software
  (OS 3.1.2), **not** by running anything on a physical Playdate. Treat these as the best current answer; a
  hardware measurement wins when one disagrees.
- **"Confirmed on hardware"**: run on a physical Playdate. Nothing in this repository has been confirmed on hardware
  yet; this marker is reserved for when the probes are run on a device.
- "Check on hardware" flags a point where the Simulator and the analysis disagree or where neither covers the case.

Where the Simulator and the device differ, an emulator should follow the device; see
[compatibility/simulator-vs-device.md](compatibility/simulator-vs-device.md).

## Contents

| Area | Files |
| --- | --- |
| Graphics | [drawing](graphics/drawing.md) (lines, shapes, fills, patterns), [display](graphics/display.md) (frame buffer, offset, clip, stencil, contexts, refresh), [images](graphics/images.md) (bitmaps, scaling, rotation, sampling, blur, fades, tables, video), [text](graphics/text.md), [sprites](graphics/sprites.md), [collisions](graphics/collisions.md) (collisions, geometry, path finding) |
| Audio | [synth](audio/synth.md), [players](audio/players.md) (samples, file players, formats), [sequences](audio/sequences.md) (sequences, MIDI), [effects](audio/effects.md) (channels, mixer, effects, signals) |
| Lua | [runtime](lua/runtime.md) (environment, import, errors, frame loop, memory), [objects](lua/objects.md) (how native objects appear in Lua) |
| C API | [calls](c-api/calls.md) (calling conventions, varargs, formatString/parseString, enums, callbacks), [state](c-api/state.md) (what C and Lua share) |
| Data | [json](data/json.md), [files](data/files.md) (file system, datastore, pdxinfo) |
| System | [time](system/time.md), [input](system/input.md) (buttons, crank, accelerometer, keyboard), [menu](system/menu.md) (system menu, device info, network) |
| Platform | [cpu-and-memory](platform/cpu-and-memory.md) (the CPU, floating point, memory and the 16 MB heap as games see them, the C API's ABI, callbacks, what game code may do) |
| Compatibility | [games](compatibility/games.md) (what real games rely on), [simulator-vs-device](compatibility/simulator-vs-device.md) |
| Tests | [tests](tests/README.md): the probes (Lua and C programs with Simulator reference outputs) and tools (fuzzers, a Simulator driver, comparison scripts) |

## Running the probes

See [tests/README.md](tests/README.md). In short: build a probe with the SDK's `pdc` (Lua) or its Makefile (C),
run it in the Simulator and in the emulator under test, and compare the console output with `expected/`.

## Not included

No part of the Playdate SDK, its examples or assets, and no game code or assets. Probes that need an asset say
which one in their README.

## License

MIT (see `LICENSE`). Made with AI assistance; see [NOTICE.md](NOTICE.md) for what that means for copyright, and for
the trademark and SDK notices. Playdate is a trademark of Panic Inc.; this project is not affiliated with Panic.
