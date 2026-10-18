# The Lua Runtime

This file describes the Lua environment a Playdate game runs in, as seen by game code: the Lua version and number
format, the globals that exist before any CoreLibs file is imported, how `import` behaves, how API functions check
their arguments and word their errors, where errors point, how the main chunk, `playdate.update` and coroutines are
scheduled, garbage collection and memory, and which standard libraries are missing. How native objects look to Lua
(userdata, metatables, identity) is in [objects.md](objects.md). The Lua C API that C code uses (`pd->lua`) is in
[../c-api/state.md](../c-api/state.md). Behaviour is given for the device (3.1.2, by analysis) and the Simulator (SDK
3.1.1); where they differ, both are stated.

## The Lua Build

- **Version.** The Playdate runs Lua 5.4. Its error messages are those of Lua 5.4.3 and later: calling a nil method
  says "method 'x' is not callable (a nil value)" (in the Simulator (SDK 3.1.1), and on the device (3.1.2, by
  analysis)), where Lua 5.4.0 to 5.4.2 said "attempt to call a nil value (method 'x')"; a bad to-be-closed value says
  "variable 'x' got a non-closable value" (5.4.0 to 5.4.2: "attempt to close non-closable variable 'x'"). An
  implementation built on an older 5.4 release should backport `luaG_callerror` and the 5.4.3 to-be-closed check to get
  the same strings.
- **Precompiled chunks only.** Games ship bytecode compiled by `pdc` (the 5.4.0-beta bytecode format). On the device
  (3.1.2, by analysis) Lua has no source parser, so game code never sees parser or lexer error messages.
- **Compile-time extensions.** `pdc` accepts the SDK's compound assignment operators (`+=`, `-=` and the rest) and
  compiles them to ordinary bytecode; the runtime needs nothing for them.
- **Call depth.** C calls and Lua calls are counted separately (the 5.4.2+ call loop):
  - Lua-to-Lua calls do not nest on the C stack. Plain Lua recursion runs until memory runs out (about 280,000
    levels in `tests/probes/deeprec`).
  - A chain of C boundaries (a C function that calls back into Lua: `pcall`, `table.sort` with a comparator, API
    callbacks) stops with "C stack overflow" at about 200 levels. The Simulator reports it at depth 199
    (`tests/probes/stackq`, `tests/probes/ccdepth`).
  - The same limits hold inside coroutines the game creates. A trap for implementers: resuming the update coroutine
    with no "from" state in Lua 5.4.0 gives it only a small fraction of the C-stack budget, and a game's recursive
    generator coroutine (about a hundred levels deep, yielding now and then) then fails with "C stack overflow".
    Resume the update coroutine from the main state.

## Numbers

- **32-bit integers and 32-bit floats.** `math.maxinteger` is 2147483647. Floats are single precision: `1/3` prints as
  0.333333343267, and 2^24 + 1 is not representable.
- **Integers and floats are distinct** (Lua 5.4 subtypes). `tostring` shows "4" for one and "4.0" for the other,
  and `math.type` tells them apart, so a game that prints or saves a returned value shows a different string if the
  wrong subtype is returned. Measured:
  - **Floats:** `gfx.getColor`, `getBackgroundColor`, `getLineWidth`, `getDrawOffset`, `getFontTracking`,
    `imageSizeAtPath`, a sprite's `getGroupMask` and `getCollidesWithGroupsMask`, `playdate.sound.getSampleRate`,
    `sound.getCurrentTime()` (seconds), a pathfinder node's `id`, `x` and `y` (so node IDs print as "2.0"), and every
    geometry field.
  - **Integers:** `display.getMosaic`, `display.getSize` (400, 240, like `getWidth` and `getHeight`),
    `display.getOffset`, `imagetable:getSize`, `tilemap:getSize`, `video:getSize`, a sample's `getSampleRate`,
    `polygon:count()`, `apiVersion()`, `gfx.getClipRect` and `getScreenClipRect`, the text constants, and the
    width and height `gfx.drawText` returns.
- **Integer arguments arrive exactly.** An API function that takes an integer reads it as a Lua integer, not
  through a float: `playdate.timeFromEpoch(762843967, 0)` gives 05:06:07. Converting through a 32-bit float rounds
  every integer above 2^24 (16,777,216), which breaks epochs, seeds, sizes and IDs.
- **Floats where an integer is expected.** Converting NaN or an out-of-range float to a C integer is undefined; the
  Arm float-to-integer conversion saturates (NaN becomes 0, values out of the 32-bit range clamp), which makes a safe
  choice. Some functions check for an integer (`luaL_checkinteger` style) and raise an error for an infinite value
  (the octave count of `gfx.perlin`, for example).
- **Booleans are booleans.** Functions documented to return a boolean return `true` or `false`, never 0 or 1
  (`sprite:isVisible`, `updatesEnabled`, `collisionsEnabled`, `isCrankDocked`, `getReduceFlashing`, `getFlipped`,
  `shouldDisplay24HourTime`, `file.rename`, every audio `isPlaying`, `sample:decompress`). Because 0 is truthy in
  Lua, `if not sprite:isVisible()` silently never runs if an integer is returned. Note that the C function behind
  `file.rename` returns 0 for success, so the Lua result is its inverse.

## Standard Libraries

Measured on every key of `_G` and of each library table (`tests/probes/reqq`):

- **Missing:** `require`, `package`, `dofile`, `loadfile`, `io` and `os`. A game cannot reach the host's files or
  run commands; an emulator that opens the full standard library lets games behave differently (a game that forgets
  an `import` or tests for `io` takes another path).
- **`debug`** has only `getinfo` and `traceback`.
- **`table`** has the Playdate additions `table.getsize`, `table.create(arrayCount, hashCount)`,
  `table.indexOfElement`, `table.shallowcopy(source, [destination])` and `table.deepcopy(source)`. There is no
  `table.getSize` (capital S).
- **`string`, `math`, `coroutine`, `utf8`** and number formatting and integer division are standard. `json` is a
  native global (see [../data/json.md](../data/json.md)).
- **String hashing** is seeded at start-up (from the time and addresses), on the device (3.1.2, by analysis) as
  well, so `pairs` order over string keys and the key order of a plain `json.encode` can change from boot to boot.
  Whether the device's seed is in practice the same at every boot is not known; check on hardware
  (`tests/probes/jsonord`). Repeatable test runs need a fixed seed.
- **Addresses** in `tostring` and `%p`: see [objects.md](objects.md#tostring-and-addresses).

## Globals Before CoreLibs

CoreLibs is Lua code that `pdc` compiles into each game; it runs only when the game's `import` reaches it. Before
that (`tests/probes/preimp`):

- **Not defined:** `class`, `Object`, `playdate.graphics.animator`, `gfx.nineSlice`, the Lua functions of
  `CoreLibs/graphics` (such as `drawCircleInRect` and `drawTextInRect`), the sprite library's Lua functions (such as
  `setBackgroundDrawingCallback` and `addEmptyCollisionSprite`), `kTextAlignment` (left 0, right 1, center 2; from
  `CoreLibs/graphics`) and `playdate.getCrankTicks` (from `CoreLibs/crank`). There is no `spritelib` global at any
  point.
- **Native and present:** every native function and class in the `playdate` table, including the sprite class and its
  methods (sprites work without CoreLibs, including `setSize`), the constants, and `playdate.graphics.kWrapClip`,
  `kWrapCharacter`, `kWrapWord` (0x1000000 to 0x1000002) and `kAlignLeft`, `kAlignCenter`, `kAlignRight` (0x2000000 to
  0x2000002); native calls use the low byte. In Lua `kStrokeInside` is 1 and `kStrokeOutside` 2, the reverse of the C
  enum.
- **Callbacks are nil until defined:** `playdate.update`, `playdate.debugDraw`, `gameWillPause` and the other
  callbacks are not predefined. There is no `playdate.geometry.polygonEdges`.
- **Environment values:**
  - `playdate.isSimulator` is 1 in the Simulator and nil on the device. Games take Simulator-only branches when it is
    truthy, so an emulator imitating the device must leave it nil (0 is truthy). One game (celeste) draws 16 clouds
    when it is set and 4 when it is nil.
  - `playdate.apiVersion()` returns two integers: the SDK version and the minimum supported version (30101 and
    10000 for SDK 3.1.1).
  - `playdate.argv[1]` is the game's name (the Simulator gives "netq.pdx"; on the device (3.1.2, by analysis) the game's
    path comes first), then any launch arguments.
  - `playdate.metadata` holds only the documented pdxinfo keys, as strings (`name`, `author`, `description`,
    `bundleID`, `version`, `buildNumber`, `imagePath`, `launchSoundPath`, `contentWarning`, `contentWarning2`), plus
    `pdxversion` as an integer. `buildtime` and the game's own keys are left out.
  - `playdate.getStats()` returns nil in the Simulator (on the device, check on hardware).
- **Overrides:** a function the game defines before importing a CoreLibs file is replaced by the import, since the
  file runs at that point.
- **Type tests in CoreLibs:** CoreLibs accepts a geometry object in place of numbers by testing
  `type(x) == "userdata"` (`drawArc(arc)`, `drawCircleInRect(rect)`, `drawTextInRect(text, rect)`, nine-slices,
  `addEmptyCollisionSprite(rect)`). Geometry objects must therefore report "userdata"; a counterclockwise arc is then
  drawn from its end angle. An emulator whose objects are tables would have to patch CoreLibs, and such patches are
  undone when the game imports the file again.

## `import`

- `import 'name'` runs a module compiled into `main.pdz`. `pdc` stores the module under the name as first written
  (for example "./scenes/Home").
- **Return value:** the first `import` of a file returns the file's return values (`home = import 'scenes/Home'`).
- **Re-import:** importing it again, under any spelling ("./scenes/Home", "scenes/Home"), returns nothing and does
  not run it again. Names are matched after normalizing a leading "./".
- **Assets:** `import 'track.png'` makes `pdc` compile the image into the PDZ as an entry of the image type, and
  `gfx.image.new('track')` then finds it (the same for tables, fonts, strings, audio and video); see
  [../data/files.md](../data/files.md).
- **Modules are not files:** the file functions do not see modules compiled into `main.pdz`
  (`file.exists("mod")` is false for a module `mod.lua`, while `main.pdz` exists).
- **`playdate.file.load(path)` and `run`** load a separately compiled `.pdz`: it holds the file's own chunk and the
  modules it imports. `load` returns a function compiled from the file's own chunk (not the first module in it), and
  the imports inside it resolve to the modules it carries. `run` returns only that function's results. A missing file
  is the error "file not found: nope.pdz" (the path as given, plus .pdz). Take care when the optional environment
  argument is omitted: the chunk's environment stays the default.

## Argument Checking and Error Messages

API functions check their arguments the way `luaL_check*` does. A wrong argument raises an ordinary Lua error,
which the game's `pcall` can catch; no argument may crash the emulator.

- **Wrong object type:** the error names the expected class:
  "bad argument #1 to 'new' (playdate.sound.channelsource expected, got playdate.sound.channel)". A function that takes
  any source or any effect says "sound source" or "sound effect".
- **Missing or nil object, missing string:** an argument error, except for the functions that accept nil:
  `gfx.pushContext()`, `gfx.sprite.new()` and `gfx.sprite.update()`, the `set...Mod(nil)` setters,
  `setMenuImage(nil)` (clears), `lockFocus(nil)`, and `setFontFamily(nil)` and `gfx.setFont(nil)` (both leave the
  font unchanged).
- **Typed numbers:** a boolean where a number is expected is an error ("bad argument #1 to 'clearMask' (number
  expected, got boolean)").
- **Omitted optional arguments** take their documented defaults (for example a `repeatCount` of 1 for players, not
  0, which means loop forever). A common mistake in a binding layer is to let an omitted argument become 0 or false.
- **Some messages, measured** (game-visible, quoted exactly):

| Call | Error |
| --- | --- |
| `playdate.setMenuImage(x)` with a non-image | "bad argument #1 to '?' (playdate.graphics.image or nil)" |
| `playdate.wait(ms)` outside `playdate.update` | "playdate.wait() can only be called from playdate.update()" |
| `image:draw("x")` | "playdate.graphics.image:draw() takes either x, y, arguments or a playdate.geometry.point object" |
| `gfx.image.new(0, 20)` | "invalid bitmap size: 0 x 20" (with the caller's position) |
| `gfx.drawPolygon` with fewer than 2 numbers | "drawPolygon expects at least 2 coordinates" |
| `gfx.fillPolygon` of an open polygon | "Can't fill an open polygon!" |
| `gfx.fillPolygon` with fewer than 6 numbers | "fillPolygon expects at least 3 x,y coordinate pairs" |
| `gfx.popContext()` with nothing pushed | "no pushed context!" |
| A fourth system menu item | "Cannot add more items to this menu." |
| `display.loadImage(path)` with a pdc-built image | "loaded file properties don't match framebuffer's" |
| `instrument:addVoice(synth)` for a synth already in use | "synths may only be in one instrument or channel at a time" |
| `setmetatable(1, t)` | "bad argument #1 to 'setmetatable' (table or userdata expected, got number)" |
| Setting an unknown field on a menu item | "Could not set value for 'foo' on playdate.menu.item" |

Loaders that fail return nil and a message instead of raising (for example `image.new` of a missing file returns nil
and "file assets/none not found: No such file"); those are listed in [../data/files.md](../data/files.md).

### Error positions

- An error raised inside an API function starts with the calling Lua line, as `luaL_error` does:
  "main.lua:6: invalid bitmap size: 0 x 20". When the API function is called straight from `pcall`
  (`pcall(gfx.image.new, 0, 20)`), there is no Lua caller and no position.
- The emulator's own failures inside an API call (a host exception, an allocation failure) must become Lua errors
  at that point, with the same position, so that the game's `pcall` catches them. The update runs in a coroutine, where
  a non-Lua failure cannot be recovered by `resume`.
- On the device (3.1.2, by analysis) an uncaught Lua error stops the game on the error screen; a hard fault in C code
  reboots.

## The Main Chunk, `playdate.update` and the Frame Loop

- **The main chunk runs in a coroutine of its own** (`tests/probes/coroq`, `tests/probes/coroq2`).
  `coroutine.isyieldable()` is true at load time, and `coroutine.running()` returns that coroutine, not the main
  thread. A `coroutine.yield(...)` in the main chunk returns nothing and the chunk continues at once: no update runs
  in between (a frame counter is still 0 after two yields). In pseudocode:

      chunk = new coroutine(main chunk)
      repeat: status = resume(chunk) until status is not "yielded"
      if status is an error: loading fails with it

- **`playdate.update()` runs in another coroutine**, so it is yieldable too.
- **Native calls see the calling thread.** An API function called from a game's own coroutine (`coroutine.wrap`,
  `coroutine.create`) reads its arguments from, and pushes its results to, that coroutine's stack. This holds for C
  functions registered through `pd->lua->addFunction` as well. Async loaders that create images and draw into them
  inside a coroutine, yielding between steps, depend on it.
- **Frame pacing:** a game at refresh rate r gets an update every 1 / r seconds, on a fixed schedule (an emulator
  that waits a full truncated period after each frame starts runs a few percent slow, about 29.4 fps at 30). The
  rate limits of `display.setRefreshRate` are in [../graphics/display.md](../graphics/display.md).
- **Order within a frame** (not measured directly; consistent with every measured case): button and crank state are
  updated, input callbacks run, deferred callbacks run (see below), then `playdate.update`, then the frame is flushed
  to the display.
- **The game clock** (`playdate.getCurrentTimeMilliseconds()` and its C equivalent) counts all time while the game
  runs, between frames and inside them: about 1,000 ms after 30 frames at 30 fps, and it advances inside a frame. All
  CoreLibs timers and animators depend on it. See [../system/time.md](../system/time.md).
- **`playdate.wait(ms)`:** the documentation says it suspends `update()` callbacks for that time. Inside
  `playdate.update`, the Simulator blocks: time has advanced when it returns (check on hardware). Outside it, it is
  an error (above). An emulator should bound a single wait, so a huge argument cannot stop it for good.
- **Callbacks delivered on the main loop.** Lua callbacks that complete asynchronous work run between frames, before
  the next `playdate.update`, never from audio processing or in the middle of the caller:
  - sound finish callbacks (a sequence's finish callback runs at the next update after it ends); see
    [../audio/players.md](../audio/players.md);
  - `playdate.getServerTime(callback)` without a network calls back at the next update with nil and
    "Internal Error: -20";
  - `playdate.scoreboards.getPersonalBest` calls back with `{ code = "ERROR", message = "Player not registered" }`
    and nil after the call returns and before the next update (offline); `addScore`, `getScores` and
    `getScoreboards` return nothing and their callbacks never run offline.
- **`playdate.restart(args)`:** the call returns and the rest of the current update runs. The game then starts again
  from scratch between frames, with a fresh Lua state and globals; the data folder is kept. The argument string is
  split at every single space and follows the game's name in `playdate.argv`, so "alpha beta  gamma" gives alpha,
  beta, an empty argument, gamma (`tests/probes/restq`).
- **`playdate.exitToLauncher()`** runs `gameWillTerminate` and ends the game.
- **Code that never returns.** On the device (3.1.2, by analysis), an update that never returns simply hangs the game.
  An emulator must still be able to stop it, including a loop that a `pcall` keeps restarting, an endless
  `coroutine.resume` or `table.sort` comparator loop (`tests/probes/runaway`), a main chunk that yields forever, and
  long pattern matches (which run no VM instructions, so a count hook alone never fires). A stop request that raises an
  error and then errors again on every instruction until the whole call unwinds cannot be swallowed by `pcall`.

## Garbage Collection and Memory

- **Collection:** the Lua collector runs every frame for at least `playdate.setMinimumGCTime(ms)` (default 1 ms),
  and longer as memory fills (`playdate.setGCScaling(min, max)`). An emulator that never collects between frames lets
  garbage pile up whose native memory the collector cannot see (an image made every frame), until the heap is full.
- **One heap:** on the device (3.1.2, by analysis) the game's Lua data and every other allocation (C allocations,
  images, sounds) share the 16 MB heap. Lua values are 4-byte numbers and pointers there. Lua run natively on a 64-bit
  host (the Simulator, or an emulator on a desktop host) takes about twice the space for the same data, so counting it
  against 16 MB makes some games run out where the device does not.
- **Finalizers:** native objects are freed by the `__gc` of their class metatable. A game that replaces an object's
  metatable drops that finalizer, so the native object is never released, on the device (3.1.2, by analysis) as well
  ([objects.md](objects.md#metatables)).
- **Streaming:** file players stream from storage and JSON decoding from C parses as a stream, so games may open many
  large files within 16 MB; an emulator should not load such files whole into the emulated heap.
- **Fonts and glyphs** cost about their file size on the device (3.1.2, by analysis); making a bitmap per glyph at load
  time exhausts the heap for large fonts (NotoSans).

## Open

- Whether the device's addresses are the same from run to run (so that address-dependent behaviour such as `pairs`
  order over object keys repeats) is not known; check on hardware (`tests/probes/heapaddr`).
