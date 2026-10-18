# Calling the C API

This file describes what an emulator must get right when emulated game code calls the Playdate C API and when the
API calls back into the game: the calling convention, variadic functions, the exact behaviour of `formatString`,
`vaFormatString`, `logToConsole` and `parseString`, enum sizes, NULL and opaque-pointer arguments, callbacks, the
event handler, memory allocation as the game's C library sees it, and the API functions that do little or nothing on
the device. State shared or kept separate between C and Lua, and the Lua C API (`pd->lua`), are in
[state.md](state.md). The CPU, the memory games can observe and the call ABI are in
[../platform/cpu-and-memory.md](../platform/cpu-and-memory.md).

## Calling Convention

Games are compiled for the Cortex-M7 with `-mthumb -mcpu=cortex-m7 -mfloat-abi=hard -mfpu=fpv5-sp-d16`, so every
call follows the Arm procedure-call standard (AAPCS) with the hard-float (VFP) variant:

- Integer and pointer arguments go in r0 to r3, then on the stack; results in r0 (and r1 for 64-bit values).
- 64-bit integers and doubles take an even/odd register pair, or an 8-byte-aligned stack slot; a register or stack
  word may be skipped to reach that alignment.
- In a non-variadic function, `float` and `double` arguments travel in the FPU registers (s0 to s15, d0 to d7),
  and float results come back in s0.
- Arguments narrower than 4 bytes (`char`, `short`, `bool`, and one-byte enums, below) still take a whole register or
  4-byte stack slot.

An emulator reads the arguments of each API call from the emulated registers and stack by these rules, converts
emulated addresses to host pointers (checking the whole range, not just the start), calls its implementation, and
writes the result back. A callback into the game is the reverse: registers and stack set up by the same rules, then
the emulated CPU runs at the callback's address.

## Variadic Functions

`logToConsole`, `error`, `formatString`, `parseString` and the other `...` functions use the base (non-VFP) AAPCS
for their variable arguments:

- Every variadic argument is in core registers or on the stack, never in FPU registers.
- A `float` is promoted to `double`; `char` and `short` are promoted to `int`.
- A double or a `long long` starts on an 8-byte boundary, so after an odd number of 4-byte arguments one word is
  skipped (`tests/probes/fmtq`).
- `vaFormatString` receives a `va_list`, which on Arm is a pointer to the saved argument area; it is read with the
  same slot and alignment rules.
- The argument types are determined by the format string. printf rules and scanf rules differ: for scanf-style
  functions every conversion is a pointer (`%f` is a `float *`, not a double), `*` means a suppressed assignment (no
  argument) rather than a width argument, and `%[...]` is a conversion.

**Porting trap.** If the host calls its own implementation through a generic call mechanism (such as libffi), it
must call variadic functions as variadic (`ffi_prep_cif_var`, with the count of named parameters, and the variadic
integers promoted to int). Calling them as if every parameter were named happens to work on x86-64 and 32-bit Arm,
but not on WebAssembly (where `...` is a buffer passed by address) or Apple's arm64 ABI (where variadic arguments are
always on the stack).

## `formatString`, `vaFormatString` and `logToConsole`

These format exactly as C's `snprintf` (`tests/probes/fmtq`, `tests/tools/fmtfuzz` compare with the host's
`snprintf`):

- Widths and precisions from arguments work: `formatString(&s, "%*d|%-*d|%.*f|%.*s|", 6, 42, 6, 42, 2, 3.14159, 2,
  "xyz")` gives `"    42|42    |3.14|xy|"`.
- Doubles and 64-bit integers anywhere in the list format correctly: `"%d %f %d %f %d %f %d %f"`,
  `"%lld %d %lld %d"`.
- `formatString` and `vaFormatString` allocate the result with the system allocator, with no length limit, and
  return a null-terminated string (the game frees it). The return value is the length.
- `%n` and a NULL output pointer are undefined on the device (3.1.2, by analysis); an emulator should stop the game with
  an error rather than write through them.
- `logToConsole` formats the same way and writes a line to the console.

## `parseString`

`parseString(str, format, ...)` behaves as C's `sscanf` (`tests/probes/scanq`, `tests/tools/scanfuzz`):

- It stores into the game's variables through the pointers passed, and returns the number of conversions assigned:
  `parseString("1.5 7 abc", "%f %d %15s", &f, &i, word)` returns 3 and fills all three.
- A suppressed conversion is not counted: `"%*d %d %d"` on "12 34 56" returns 2 and reads 34 and 56.
- Scan sets: `"%[^,],%15s %d"` on "abc,def 7" returns 3; `"%[ab]z %d"` on "aabbz 9" returns 2 ("aabb", 9).
- Field widths limit what is read and stored: `"%3s%s %s"` on "abcdef  gh" stores "abc", then "def" and "gh"; `%4d`
  reads at most four characters; `"%2d %d"` reads 12 and 34 from "1234".
- Length modifiers store values of their size: `%hd`, `%hhu`, `%ld`, `%lld`, `%llx`, `%lf`.
- A space in the format matches any amount of white space, including none.
- Input that runs out before anything is assigned returns -1.
- On the device (3.1.2, by analysis) out-of-range integers saturate; a glibc host `sscanf` wraps, so it is not a
  perfect reference there.

## Enum Sizes

The SDK's toolchain (arm-none-eabi) uses EABI short enums, and the SDK's build does not turn them off. An enum
whose values fit in a byte is one byte (`sizeof(PDButtons)` and `sizeof(SoundFormat)` are 1). So functions that
write an enum through a pointer store one byte (`tests/probes/enumq`):

- `system->getButtonState(&current, &pushed, &released)` stores one byte into each;
- `sound->sample->getData(sample, &data, &format, &rate, &length)` stores one byte into `format`.

Storing 32 bits there overwrites the three bytes after each variable; with three `PDButtons` declared next to each
other, a store into a later one clears part of an earlier one. By the same rule, an enum field inside an API
structure is one byte wide.

## Object and Pointer Arguments

- **NULL object:** on the device (3.1.2, by analysis), most C API functions check their object argument for NULL and
  then do nothing. Nothing else is checked there: a dangling or wrong pointer, or a buffer shorter than its count, is
  undefined behaviour there. An emulator must not crash or hang on any of them; stopping the game with an error
  that names the function is the closest match to a fault on the device.
- **Functions that take NULL on purpose:**
  - `graphics->pushContext(NULL)`: the display frame buffer (see [state.md](state.md#contexts));
  - `graphics->setFont(NULL)`: the system font;
  - `graphics->setStencil(NULL)`: no stencil;
  - `system->setMenuImage(NULL, 0)`: no menu image;
  - the text measuring functions (`getTextWidth`, `getTextHeightForMaxWidth`) with a NULL font: the current font;
  - `graphics->getFontHeight(NULL)` returns 0;
  - the menu item functions accept a NULL item (a game may set an item's value before creating it);
  - NULL error pointers (`outerr`) in `loadBitmap`, `loadIntoBitmap`, `loadBitmapTable`, `loadIntoBitmapTable` and
    `loadFont`;
  - `file->stat(path, NULL)`, used as an existence check, works;
  - file functions with a NULL path (`open`, `listfiles`, `mkdir`, `unlink`, `rename`) fail, returning NULL or -1.
- **Opaque values:** `userdata` and context values passed to the API (menu items, button callbacks, `listfiles`,
  update callbacks, sprite and audio userdata) are only stored and handed back, so any 32-bit value works, including
  small integers such as `(void *)1`. They must not be translated as addresses.
- **Strings:** a game string is read only as far as the game's memory goes. NULL text is undefined on the device;
  treating it as empty is a safe choice.
- **Huge sizes and coordinates** must not make the host loop: work should be bounded by the clipped output (see
  [../platform/cpu-and-memory.md](../platform/cpu-and-memory.md#what-game-code-may-and-may-not-do)).

## Callbacks into the Game

The API calls back into game code with the AAPCS rules above. Points that matter:

- **Userdata** given at registration is passed back unchanged (menu item callbacks receive it, and
  `getMenuItemUserdata` returns it).
- **`file->listfiles(path, callback, userdata, showhidden)`** calls `callback(name, userdata)` for each entry, with
  `name` in emulated memory, in alphabetical order, directories with a trailing slash.
- **Sprite draw functions** set from C receive the sprite's bounds and the dirty rect in screen coordinates; the
  sprite's position is not added to the draw offset for them (unlike Lua draw callbacks). See
  [../graphics/sprites.md](../graphics/sprites.md).
- **Collision response functions** run once per detected collision.
- **Audio callbacks:** C custom sources (`sound->addSource`, `channel->addCallbackSource`) and effects
  (`effect->newEffect`, whose process callback takes five arguments: the effect, left and right buffers, the frame
  count and whether the input is active) run inside the audio render. On the device (3.1.2, by analysis) the render runs
  every 256 frames and preempts the game wherever it is, except inside a sound API call. An emulator needs its own stack
  for these calls if it runs them while game code is suspended. See [../audio/effects.md](../audio/effects.md).
- **`system->getServerTime(callback)`** without a network calls back after the next update callback, with NULL and
  an error string ("Internal Error: -20").
- **Native code that never returns:** on the device (3.1.2, by analysis) the game hangs; an emulator must still be able
  to stop it.

## The Event Handler

The game's `eventHandler(PlaydateAPI *pd, PDSystemEvent event, uint32_t arg)` is called with:

| Event | When |
| --- | --- |
| `kEventInit` | Once at start, before the first update. The game sets its update callback here (`system->setUpdateCallback`) |
| `kEventInitLua` | In a game with Lua, once the Lua state exists and before `main.lua` runs: register C functions and classes here (`lua->addFunction`, `lua->registerClass`) |
| `kEventPause`, `kEventResume` | When the system menu opens and closes |
| `kEventKeyPressed`, `kEventKeyReleased` | Keyboard keys in the Simulator (`arg` is the key code) |
| `kEventLock`, `kEventUnlock` | Device lock and unlock |
| `kEventLowPower` | The device is about to sleep for low power |
| `kEventTerminate` | The game is ending |
| `kEventMirrorStarted`, `kEventMirrorEnded` | Mirror connections |

A C update callback set during `kEventInitLua` together with a Lua `playdate.update` is a case worth testing
(`tests/probes/updq`). A C-only game has no Lua state, so API functions that would call Lua (for example a sprite
update function) must work without one.

## Memory Allocation

- On the device (3.1.2, by analysis), the SDK's `setup.c` routes a game's `malloc`, `realloc` and `free` to
  `system->realloc`. `calloc` is not routed through the API: it comes from the C library linked into the game. It
  calls `malloc`, then expects the word before each block to hold the block's usable size + 4 (the low two bits
  ignored) and clears that size minus 4 bytes, at least 12.
- An emulator's allocator must therefore write such a size word (usable bytes + 4) before every block and make no
  block smaller than 16 bytes, or every `calloc` clears the wrong amount (a 0 there makes it clear about 4 GB).
- Freed memory is reusable, double frees should be reported, and the heap must be executable: some C games
  (emulators such as ArduDate) compile code into a heap buffer and jump to it. See
  [../platform/cpu-and-memory.md](../platform/cpu-and-memory.md#memory-a-game-can-observe) for the DTCM and
  executable memory.
- `newSampleFromData` with `shouldFreeData` set frees the data with the system allocator later, so the data must be a
  heap block; anything else is undefined on the device (check on hardware).

## Functions That Do Little or Nothing

Measured results for API functions that are easy to leave as stubs (`tests/probes/cprobe` and the probes named):

- `graphics->setColorToPattern(&color, bitmap, x, y)`: a pattern colour from the bitmap's 8 by 8 region at (x, y),
  wrapping at its edges.
- `graphics->getFontGlyph(font, c, &bitmap, &advance)`: the glyph, its bitmap and advance ("A" is 9 in the system
  font).
- `graphics->makeFontFromData`: wraps the given data (a pft file's contents after its 16-byte header). The
  deprecated two-argument form is the same as the current one with a length of 0, which leaves the reads unbounded.
  Both return a live font.
- `sound->addSource`, `channel->addCallbackSource` and `channel->getOutputAsSource` return sources;
  `signal->newSignalForValue` returns a signal for an LFO or envelope.
- Stream players have a video player and a file player from the start (`getVideoPlayer`, `getFilePlayer`);
  `setBufferSize` is accepted.
- `video->renderFrame` out of range returns 0 without recording an error; `loadVideo` of a missing file returns NULL.
- `graphics->drawScaledBitmap` with a zero or negative scale draws nothing.
- `network->getStatus()` reports not connected (0) in the Simulator.
- `http->newConnection` returns NULL without network permission; `tcp->newConnection` always makes the object, and
  `tcp->open` then returns -20 without permission. On the device (3.1.2, by analysis) the first access shows the "Allow
  Internet Access?" prompt; an emulator without a prompt can decline (`requestAccess` returns `kAccessDenied`).
- `system->addMenuItem` and the checkmark and options variants return NULL for a fourth item.
- `system->getLaunchArgs(&path)` sets `path` to the game's name.
- `system->restartGame(args)` returns; the rest of the update runs, then the game restarts with a fresh state (see
  [../lua/runtime.md](../lua/runtime.md)).
- `system->error(fmt, ...)` ends the game with the message.
- Network objects opened and closed without a connection return without effect (their exact return values are not
  yet compared).
- C text functions (`drawText`, `drawTextInRect`, `getTextWidth`) draw with the current font alone: `*` and `_` are
  ordinary characters, unlike Lua's `gfx.drawText`. `drawText` returns the drawn width. See
  [../graphics/text.md](../graphics/text.md).
- In the Simulator, `sprite->allOverlappingSprites` crashes, and `sound->setOutputsActive` aborts when there is no
  audio device; the device's results are not known.
