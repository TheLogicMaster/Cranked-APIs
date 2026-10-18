# The CPU and Memory as Games See Them

This file describes the platform that the native (C) part of a Playdate game runs on: the CPU and the instruction
set the SDK builds for, its floating-point behaviour, the memory a game can observe (executable regions, addresses,
the 16 MB heap it shares with Lua), how game code calls the C API and how the system calls back into it, and what
game code may and may not do. Lua-only games run in the system's Lua VM and touch little of this beyond the shared
heap. The details of each API call's arguments are in [../c-api/calls.md](../c-api/calls.md), the state shared with
Lua in [../c-api/state.md](../c-api/state.md), and Lua's own limits in [../lua/runtime.md](../lua/runtime.md).

## The CPU

Both Playdate revisions use an Arm Cortex-M7 at 168 MHz with 16 MB of RAM (revision A: STM32F746, revision B:
STM32H7B0). The SDK compiles games with

```
-mthumb -mcpu=cortex-m7 -mfloat-abi=hard -mfpu=fpv5-sp-d16
```

so game code is ARMv7E-M:

- Thumb and Thumb-2 only (M-profile cores have no 32-bit Arm state);
- the DSP extension: SIMD, saturating and multiply-accumulate instructions;
- the FPv5 single-precision FPU with 16 double-width registers (D0 to D15). Double-precision arithmetic is done in
  software by the compiler's runtime library, so game code needs no double-precision hardware. Registers D16 to D31
  and Advanced SIMD do not exist;
- the hard-float procedure-call standard (AAPCS-VFP): float arguments and results travel in S/D registers.

Game code has no need to take interrupts or program the system control space or the MPU; an emulator need not provide
them. Compilers do not emit UNPREDICTABLE encodings (SP or PC where the architecture forbids them, should-be-zero bits
set, D16 to D31, Advanced SIMD); emulation engines disagree on them, and no game depends on them.

**Exclusive access.** `STREX` without an open reservation fails, and succeeds only for the reserved address. Taking
an exception clears the exclusive monitor, so an `LDREX`/`STREX` sequence interrupted by the system retries. An
emulator that runs a callback (for example an audio callback) in the middle of game code and then restores the
interrupted context should clear the monitor too, or the interrupted `STREX` can wrongly succeed.

**Signed overflow wraps.** Integer arithmetic on the device wraps; there is no undefined behaviour at the machine
level. API arguments near 2^31 (coordinates, sizes) therefore give wrapped results on the device, and a host
implementation in C or C++ needs wrapping arithmetic (for example `-fwrapv`) to give the same ones.

### The game binary

A game is shipped as `pdex.bin` (the device build) and, for the Simulator, `pdex.so` (a host shared library). The device
runs only `pdex.bin`; a bundle with only `pdex.so` (some games ship that way) has no native code an emulator of the
device can run, only its Lua part. On the device (3.1.2, by analysis) `pdex.bin` is relocated at load to wherever the
system places it. A loader should treat the file as untrusted: patch possibly unaligned words with copies, skip
relocation offsets outside the code, check the header and table sizes, and compare the magic with a length-limited
comparison (a short file has no terminator).

## Floating Point

- **Fused multiply-add.** On the device (3.1.2, by analysis) `a*b+c` in game code is rounded once, and `sinf`, `cosf`,
  `atan2f` come from the ARM build's math library (linked into the game). The Simulator's x86 build rounds twice and
  uses the host's math library. A game that runs these every frame (Spaceshipment's gravity step) drifts apart between
  the two after a few hundred frames, so C float results must be compared with the device or with an emulator running
  `pdex.bin`, never with the Simulator. A fused multiply-add rounds once, bit for bit as IEEE `fmaf()`
  (`tests/probes/fmaq` hashes 2000 fused and split multiply-adds and the ARM build's `sinf`, `cosf` and `atan2f`
  results).
- **FPSCR mode.** Whether the device's OS starts game code with flush-to-zero or default-NaN set is not known;
  check on hardware (`tests/probes/fmaq` answers it: its hashes change if either bit is set). Until then the
  architectural default (round to nearest, no flush-to-zero, no default-NaN, denormals kept) is the best answer.
  Game code may set either bit itself, so both must work.
- **Float-to-integer conversion saturates** on ARM (out-of-range values clamp, NaN gives 0), while x86 gives the
  "integer indefinite" value `0x80000000`. Some API results differ between the device and the Simulator in the same
  way (for example the square wave duty cycle: 0.5 or more stores as `0x7FFFFFFF` on the device (3.1.2, by analysis)
  and `0x80000000` in the Simulator; see [../audio/synth.md](../audio/synth.md)).
- **Double precision** is common in game code (C's `double` literals and maths functions); it runs as integer code
  in the compiler's software routines, so its results depend only on the integer instructions.

The FPU's other rules, all architectural:

- NaN propagation in operand order (the first signalling NaN, else the first quiet NaN), with signalling NaNs
  quietened;
- the default NaN for invalid operations, and for every NaN result in default-NaN mode;
- flush-to-zero of inputs and results when FPSCR.FZ is set;
- the four rounding modes;
- saturating float-to-integer conversions, NaN to 0;
- half-precision conversions.

In the default mode, IEEE add, subtract, multiply, divide and fused multiply-add on any host give the same result as
the FPU for every non-NaN result, so only NaN results and non-default modes need ARM-specific handling. FPSCR's
cumulative exception flags (IOC, DZC, OFC, UFC, IXC) are visible only to code that reads FPSCR.

## Memory a Game Can Observe

A game cannot see the device's physical memory map except in the ways below, so an emulator is free to place
regions where it likes.

- **The DTCM.** The Cortex-M7's 128 KB of tightly coupled RAM at `0x20000000` exists, and some games copy code into
  it and run it there.
- **The heap is executable.** Emulators-in-a-game (ArduDate, which compiles Arduboy code into a buffer, and others)
  jump into code they wrote into the heap or the DTCM. An emulated heap must lie in an executable region: a heap at
  `0xA0000000`, for instance, is inside the region the Cortex-M default memory map makes execute-never, and the first
  compiled block faults.
- **Self-modifying code works.** A function rewritten in the heap after it has run runs its new code.
- **Addresses are visible.** `tostring` of a table, function, thread or userdata and `string.format("%p", v)` show
  the object's address. On the device (3.1.2, by analysis) that is a 32-bit value printed as `0x` and unpadded
  lowercase hex (check on hardware; `tests/probes/heapaddr`). The Simulator (SDK 3.1.1) prints its own 64-bit host
  addresses. Games that parse these strings break on 64-bit values, so an emulator should print 32-bit addresses.
  Whether the device's addresses are the same from run to run (the same gaps between objects) is not known; check on
  hardware (`tests/probes/heapaddr` records it).
- **Pointers the game holds are 32-bit** everywhere: in API structures, in callback arguments, in `userdata` values
  the API only stores and hands back (see [../c-api/calls.md](../c-api/calls.md#object-and-pointer-arguments)).

## The 16 MB Heap

One 16 MB heap holds everything the game allocates through `system->realloc` and the C library (the SDK routes `malloc`,
`realloc` and `free` there; `calloc` is not routed through the API but comes from the C library linked into the game,
see [../c-api/calls.md](../c-api/calls.md#memory-allocation)), Lua's allocations, and the memory of most native objects
(bitmaps, samples and the rest).

What games observe of the allocator:

- Freed blocks are reusable, wherever they are; a long-running game that allocates and frees every frame does not
  run out.
- `calloc` expects the word before each block to hold the block's usable size + 4 (the low two bits ignored) and
  clears that size minus 4 bytes, at least 12. That word must keep this meaning whatever the host's pointer size.
- Freeing something that is not a heap block (for example `newSampleFromData` with `shouldFreeData` on data outside
  the heap) is undefined on the device (check on hardware); an emulator should stop the game with an error instead. A
  double free should be reported as an error.
- **Running out.** When a request cannot be met, the API returns its failure value (on the device (3.1.2, by
  analysis); check on hardware): for example `sample.new(seconds)` larger than the heap holds returns nil.

**What does not count against the 16 MB.** Games are sized for the device, which streams or keeps compact several
things that a naive implementation loads whole:

- file-player audio is streamed from storage, not decoded into the heap (a game with a dozen tracks otherwise runs
  out);
- C `json->decode` parses as a stream, so decoding a large file (a 632 KB world file) does not need the whole input,
  or every string handed to the game, in the heap at once;
- font glyph bitmaps can be made on first use rather than for every glyph at load.

### Lua in the same heap

On the device (3.1.2, by analysis), Lua (5.4, 32-bit numbers and pointers) allocates from the same 16 MB as the game's C
code. A Lua running natively on a 64-bit host stores values and pointers at twice the size, so the same Lua data takes
about twice the space (the Simulator, also 64-bit, uses that amount). Counted against 16 MB, some games then run out
that fit on the device. An emulator on a 64-bit host therefore needs extra room for Lua (for example a separate region
for Lua; on a 32-bit host the 16 MB heap can be shared as on the device).

Lua's collector runs every frame for at least `setMinimumGCTime` (default 1 ms), and more as memory fills
(`setGCScaling`). Native objects are freed by their `__gc`: a game that makes a native object every frame relies on
the collector to release the native memory (20 fonts a frame without that fill the 16 MB in a few seconds). See
[../lua/runtime.md](../lua/runtime.md#garbage-collection-and-memory).

## Calling the C API

The game receives a pointer to the `PlaydateAPI` structure in its event handler and calls every API function through
the function pointers in it and its sub-structures. Calls follow AAPCS-VFP: integer and pointer arguments in R0 to
R3 and then the stack, float arguments in S0 to S15 (doubles in D0 to D7), results in R0/R1 or S0/D0, return address
in LR. An emulator can make those pointers lead to addresses that trap into the host, read the arguments from the
registers and stack, and write the result back.

Points of the ABI that bite (details in [../c-api/calls.md](../c-api/calls.md)):

- **Variadic functions** (`logToConsole`, `formatString`, `error`, `parseString` and the rest) receive their
  variadic arguments by the variadic rules: integers promoted to `int`, floats to `double`, 64-bit values 8-byte
  aligned. The number and types of variadic arguments come only from the format string, by the rules of the
  function's family: for printf-style functions `*` is a width argument; for scanf-style functions every conversion
  is a pointer, `*` suppresses an assignment (it takes no argument), and `[...]` is a conversion. Reading a scanf `%f`
  as an 8-byte double misreads every argument after it. A host implementation called through a generic mechanism
  must also be called as variadic: on some host ABIs (WebAssembly, Apple arm64) variadic arguments travel
  differently from named ones.
- **`va_list` arguments** (`vaFormatString`) follow ARM's rules: a value narrower than 4 bytes still takes a 4-byte
  slot, 64-bit values are 8-byte aligned.
- **Enums are one byte.** arm-none-eabi uses EABI short enums, and the SDK's build does not turn them off, so
  `PDButtons` and `SoundFormat` have `sizeof` 1. `getButtonState` and `sound->sample->getData` store one byte through
  their output pointers; storing 32 bits overwrites the game's neighbouring variables (`tests/probes/enumq`).
- **Arguments are untrusted.** Pointers (with their lengths), sizes, enum values and callback addresses come from
  game code; a bad one is a game error, never a reason for the host to crash.

## Callbacks Into Game Code

Callbacks the game registers (the update callback, menu callbacks, sprite update and draw functions, collision
responses, audio sources and effects, Lua C functions) are called with the same AAPCS-VFP convention, on the game's
stack, and return to the system. Calls nest freely: native code calls the API, which calls Lua, which calls a native
Lua function, which calls the API again. Each level must leave the state of the code it interrupted intact.

For a C function registered with `lua->addFunction`, the arguments come from the Lua thread that called it (a coroutine,
if it was called from one), and its results go back to that thread (see
[../c-api/state.md](../c-api/state.md#registration)).

On the device (3.1.2, by analysis), Lua counts C calls and Lua calls separately: Lua-to-Lua calls do not count as C
levels, a chain of C boundaries (native functions calling back into Lua, `pcall`, `table.sort` with a comparator, API
callbacks) stops with "C stack overflow" at about 200 levels (the Simulator (SDK 3.1.1) reports it at depth 199), and
plain Lua recursion runs until memory runs out (`tests/probes/deeprec`: about 280,000 levels). Lua-to-native-to-Lua
loops therefore end with the Lua error, not with a crash. Details in [../lua/runtime.md](../lua/runtime.md).

## What Game Code May and May Not Do

Game code may:

- run any ARMv7E-M user-mode instruction with the FPv5 single-precision FPU, read and write FPSCR, and use
  `LDREX`/`STREX`;
- copy code into the DTCM or the heap, modify it, and run it;
- format and parse the addresses of its own objects, which are 32-bit;
- keep arbitrary 32-bit values in pointer-sized fields that the API only stores and hands back;
- allocate up to the 16 MB it shares with Lua, and be told (nil or NULL) when that runs out.

Game code may not, or gains nothing from trying:

- take interrupts, or program the system control space or the MPU (an emulator need not provide them);
- use D16 to D31 or Advanced SIMD (they do not exist on the device), or rely on double-precision FPU instructions
  (the SDK's build does not emit them, and revision A's single-precision FPU has none);
- rely on the physical placement of the code, stack or API structures;
- free memory that did not come from the heap.

**Code that never returns.** On the device (3.1.2, by analysis), a game whose update callback (or main chunk, or a Lua
loop inside `pcall`, `coroutine.resume` or a `table.sort` comparator) never returns simply hangs. An emulator must still
be able to stop it, so it has to bound native code and Lua code without the game's help, for example by checking a stop
flag every few million ARM instructions and every few thousand Lua VM instructions, in a way the game's own `pcall`
cannot catch (`tests/probes/cloop`, `tests/probes/runaway`). Lua's pattern matcher can backtrack for a long time without
executing a VM instruction, so it needs a check of its own.

**Host work proportional to arguments.** Some API calls take time proportional to their arguments on the device
(3.1.2, by analysis), for example very long nearly horizontal lines and huge ellipses. An implementation need only
reproduce the pixels, and should bound its own work by the clipped output (see
[../graphics/drawing.md](../graphics/drawing.md)).
