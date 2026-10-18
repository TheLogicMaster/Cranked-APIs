# What Real Games Rely On

This file collects the behaviours that real Playdate games turned out to depend on: what broke in a specific game when
an emulator got it wrong, and what the game needed instead. It is grouped by API area and names the games. It also
lists the patterns a reimplementation should get right first, and describes how the games were compared against the
SDK 3.1.1 Simulator (black-box, with scripted input), so the same method can be reused. The behaviours themselves are
specified in the topic files ([graphics/drawing.md](../graphics/drawing.md),
[graphics/sprites.md](../graphics/sprites.md), [audio/players.md](../audio/players.md) and the others); this file says
why each one matters. Where the Simulator and the device differ, see [simulator-vs-device.md](simulator-vs-device.md).

## The Corpus

| Group | Size |
| --- | --- |
| Open-source Lua games | 34 |
| Open-source C games | 17 |
| More open-source Lua and C games | 22 |
| Games distributed as built bundles, without source | 28 (25 Lua, 3 C) |
| Tutorial projects, engine templates and framework examples (Noble Engine, Panels, pdDialogue, pdParticles, AnimatedSprite, "Make Games for Playdate with Lua") | about 30 |
| The SDK's own examples (Lua, C, and Lua with C) | about 50 |

Each game was compared by pixel frame dumps at fixed frames (every 60 or 75 frames, up to 900 to 1500 frames), with
the same scripted input in both environments (see "How the Games Were Tested"). Some games in the corpus could not be
built at all (missing git submodules, a private level submodule, a LOVE or Zig project that is not a Playdate game);
they are left out.

## Patterns to Get Right First

These are the behaviours that broke the most games, roughly in order of how many games they affected. A
reimplementation that gets these right will run most of the corpus.

1. **The sprite system's dirty-rect redraw.** Games depend on *what is not redrawn* as much as on what is. Drawing
   straight to the screen dirties its bounds once any sprite exists; images changed in place redraw their sprite;
   opaque sprites hide what is below them; changes made during a sprite update show a frame later. About a dozen games
   showed trails, stale text, frozen clocks or missing UI when this was simplified to "clear and redraw everything" or
   "redraw only what moved".
2. **Game time.** `getCurrentTimeMilliseconds` must count all time while the game runs, not only time spent inside
   `update()`. Every CoreLibs timer, animator and frame timer depends on it.
3. **Booleans are booleans.** API functions documented to return a boolean must return `true`/`false`, never 0 or 1:
   `0` is truthy in Lua, so `if not sprite:isVisible()` never runs.
4. **`playdate.isSimulator` is nil on the device (3.1.2, by analysis).** Any other value (including 0) sends games
   down Simulator-only paths.
5. **Fractional coordinates.** Most drawing calls round to nearest (halves away from zero), but `image:draw`,
   `drawIgnoringOffset`, `drawTiled`, `drawSampled` and the tilemap draws floor, `drawRotated` floors, and
   `gfx.image.new` truncates its size. Games that ease positions with fractional values hit all of these.
6. **Text measurement and fonts.** Signed tracking, full glyph pages, fallback to the system font, zero-width code
   points, markup rules, and font loading by source name. A wrong width moves every centered string.
7. **Asset lookup.** Images, image tables and fonts by source name (`tiles-table-8-8.png` for `tiles.pdt`), entries
   compiled into `main.pdz` by `import`, case-insensitive names, and the system assets (fonts, crank indicator,
   keyboard) that games expect the system to supply.
8. **Lua runtime details.** The value of `import`, coroutines (the main chunk runs in one; native calls must return to
   the calling coroutine), per-frame garbage collection, userdata object types, and C-stack depth.
9. **Audio clocks and callbacks.** Rhythm games and fades time themselves by `sound.getCurrentTime()`,
   `fileplayer:getOffset()` and finish or fade callbacks; a player that never advances or never calls back stalls the
   game's state machine.
10. **Memory.** The device has 16 MB. Loading fonts or file players eagerly, leaking freed heap blocks, or doubling
    Lua's footprint on a 64-bit host makes large games run out of memory.

## Behaviours by API Area

### Sprites and the dirty-rect redraw

See [graphics/sprites.md](../graphics/sprites.md).

| Game | What broke | What it needed |
| --- | --- | --- |
| playdate-breakout | "Press A to Start" stayed on screen through the game | Drawing straight to the screen dirties its bounds once any sprite has been created; the next `sprite.update()` fills that area with the background and redraws the sprites |
| bobby-playdate, godspeed, lonefury, propeller-rat | Text and effects left trails | Same rule |
| Dont-Cross-the-Streams | The map was missing in redrawn areas | The dirty bounds are the shape's bounds (a line's end-point box, an ellipse's rect), not the bounds of the pixels drawn; `gfx.clear()` dirties only the clip rect |
| core-fault | Its clock sprite froze | Drawing into a sprite's image (or `image:clear`) redraws the sprite without `markDirty` |
| untitled-roguelike | Chopped trees left mixed old and new tiles | Changing a sprite's tilemap tiles redraws the sprite |
| Overseer | Its dialogue box ran a letter ahead every other frame | An image change made *during* the sprite update is not seen by that update; it shows on the next redraw |
| dino-run | Its score lagged a frame | Lua `sprite:setImage` with the same image redraws the sprite if the image was drawn into since |
| cloudburst | Particles drifted two frames early | Occlusion: before drawing a dirty rect, the topmost opaque sprite covering it hides everything below, including the background callback |
| artillery-game | Two pixels of its rotated gun hidden | A rotated (non right-angle) sprite draws a masked copy, so it is not opaque |
| Roguelike Deckbuilder | Its hit flash never appeared | `setImageDrawMode` and `setImageFlip` with a new value mark the sprite dirty |
| godspeed | Its skull icon stayed at its first size | Changing a sprite's clip rect redraws it; an empty clip rect hides the sprite; fractional clip origins floor and sizes round up |
| BrickCrusher2020 | A text box border drew outside its sprite | A sprite's drawing is clipped to its own bounds even inside a larger merged dirty area |
| propeller-rat | Its "continue" arrow was missing | A sprite with `setIgnoresDrawOffset(true)` draws its image at its own position |
| playdate_sudoku | Buttons one pixel too wide | The Lua draw callback's rect is in sprite-local coordinates from the floored position, clipped to the sprite's size |
| playdate_sudoku | White button text vanished | A sprite's `draw` callback runs with the global image draw mode, not the sprite's own mode |
| artillery-game, archery | Rotated sprites up to 10 pixels off | A sprite rotates about its center point (`setCenter`), which stays at its position; it draws `rotatedImage` at the floored bounds |
| AnimatedSprite example, spritescaling | Flipped scaled sprites drawn unflipped, or a row off | A scaled sprite draws a scaled copy of its image with its flip, at its truncated bounds |
| smolitaire | Cards, pointer and dialogs never appeared | `sprite:update()` called on a sprite without its own update updates and draws every sprite |
| untitled-roguelike | C stack overflow | A nested `gfx.sprite.update()` (for example `Class.super.update(self)`, or from a background callback) does nothing |
| playorama | Recursion until the stack overflowed | Same rule (its background callback updates sprites through its menu) |
| quandino | Settings toggles missing | The draw pass follows the live display list: sprites added by a draw callback are drawn in the same pass if above |
| lonefury | Game state one frame early | A sprite removed during the update pass by an earlier sprite is still updated in that pass |
| untitled-roguelike | Ran in an emulator but not in the Simulator | `gfx.sprite.new` accepts only nothing, nil, an image or a tilemap; `sprite.new(100, 20)` is an error |

### Collisions

See [graphics/collisions.md](../graphics/collisions.md).

| Game | What broke | What it needed |
| --- | --- | --- |
| core-fault | The player slid off ore | `setGroups` and `setCollidesWithGroups` accept a single group number as well as a table |
| lonefury | Bullets hit an asteroid a frame early | Alpha collisions compare only the intersection of the collide rects, offset by the truncated difference of the float positions, with flips; with one masked image only the first row is read |
| SDK example "collisions" | Different bounce paths | The collision response runs only for detected hits; after a bounce only the sprite just bounced off is skipped by the next projection |
| SDK example Level 1-1 | 300,000 response calls per frame | Same rule; and a 32-pixel cell grid with incremental cell updates |
| SDK example "balls" | Order of overlap pairs | `allOverlappingSprites` order follows memory addresses (not stable, and cannot be reproduced exactly; see "Open") |

### Drawing

See [graphics/drawing.md](../graphics/drawing.md) and [graphics/images.md](../graphics/images.md).

| Game | What broke | What it needed |
| --- | --- | --- |
| moon-is-friend | Menu box one pixel off | Fractional integer arguments round to nearest, halves away from zero; `drawRect` spans round(x) to round(x + w) - 1 |
| BlockDate | Next and held pieces vanished | Fields of a rect object passed to a drawing call round like plain numbers (reading them as integers gave 0) |
| action-card-roguelike | Cards a pixel off in most dumps | `drawIgnoringOffset`, `drawTiled`, `drawSampled` and tilemap draws floor fractional positions, like `image:draw` |
| onebit frogger | A label a pixel off | `drawRotated` floors a fractional position (-2.5 is -3) |
| dino-run | Ground dashes a pixel off | `image:draw` source rect fields are floored, and a source rect starting outside the image keeps its offset |
| By the Pier | Fishing line one row taller | `gfx.image.new` truncates fractional sizes |
| By the Pier | Rod swung past its end point | An arc's span runs in its direction (counterclockwise 45 to 290 is 115 degrees) |
| simply-sudoku | Wrong rounded corners | `fillRoundRect` corner rule (a radius r corner is drawn as an ellipse of radius r + 1; radius 6 looks like 7) |
| moon-is-friend | A stray edge on an empty progress bar | Round rects of zero width or height draw nothing; radius 0 fills like radius 1 |
| bobby-playdate | Wide rounded outlines off | Wide outlines keep the outer radius |
| escape-from-complex-32 | Laser beam's round caps half a pixel off | Round caps of even widths are centered on the end point's top-left pixel corner |
| the-kings-dungeon | Its water surface (a wide polygon with fractional vertices) | Wide-line and polygon rasterization as on the device (see [graphics/drawing.md](../graphics/drawing.md)) |
| project_loose | Its stirring stick (a fractional quad) | Polygon fill as on the device, with fractional points rounded to nearest |
| SDK example Asheteroids | The thrust flame gained a third edge | `drawPolygon` does not close an open polygon; width argument; width-0 lines |
| core-fault | Scene transitions covered the whole screen | Stencils: clear pixels block like black; `setStencilImage` needs at least 32 pixels of width |
| Noodles and Love | A background cross-fade | `setStencilPattern(level, type)` builds the pattern from the type's own thresholds |
| moon-is-friend | Diagonal-line menu border | Each `setDitherPattern` type has its own ordered pattern |
| Orbeats | Its orbit ring invisible | `setDitherPattern(alpha)` without a type is Bayer 8x8, not None |
| BrickCrusher2020 | Level background | Fade thresholds of the line and Screen dither types |
| By the Pier | Title fade | `drawFaded` and `fadedImage` anchor the pattern to the destination plus the image's trimmed margin; alpha becomes floor(alpha x 255) |
| Bubble Is You | Every dump differed | Scaled drawing of images whose transparent margins pdc trimmed samples the stored rect on its own |
| Stellarator | Aiming arrow | Rotation about a center other than the middle |
| artillery-game, archery | Rotated pixels | Rotation sampling as on the device (see [simulator-vs-device.md](simulator-vs-device.md) for the remaining single-pixel differences) |
| playdate-friction | Ball images drawn offset | `lockFocus(image)` pushes a fresh context: draw offset 0 and the image as the clip rect |
| rubido (C) | The board's pegs were missing | C `pushContext(NULL)` targets the display, with the screen's own clip and offset |
| celeste | 72,000 pixels of the frame buffer | At `display.setScale(n)` the screen is the top-left 400/n by 240/n; drawing and `clear` stay inside it |
| playmon | 7 frames per second on a large tilemap | Large tilemaps are slow unless off-target images are skipped |
| SDK example Exposure | Coverage meter counts | Bitmap row sizes as C sees them: C `newBitmap` rows are a multiple of 4 bytes, Lua images `(width + 7) / 8`, the frame buffer 52; `invertedImage` leaves the stored bytes unchanged (C sees the source's bytes) |
| SDK example Level 1-1 | 3,160 phantom enemies | Tilemap tiles are stored as index - 1, so an unset tile is empty (`getTileAtPosition` gives nil, `getTiles` 65536), not tile 1; `setSize` empties the map |

### Text and fonts

See [graphics/text.md](../graphics/text.md).

| Game | What broke | What it needed |
| --- | --- | --- |
| propeller-rat | Title prompt never appeared | A font's tracking is a signed byte (`tracking=-2`) |
| FactoryFarming (C) | Crashed loading NotoSans | A font page's glyph count byte is 0 for a full page of 256; use the page's usage flags |
| FactoryFarming | Out of memory | Make glyph bitmaps on first use, not for every glyph at load |
| notes app of playdate-chinese-IME | Replacement boxes | Wide fonts (flag bit 0: 128 bytes of page flags); kerning entry formats |
| lonefury | Could not start | `gfx.font.new` accepts a font's source name (`Score-table-8-16.png` for `Score.pft`) |
| znax (C) | Crashed | The Roobert system fonts exist under `/System/Fonts`; `getFontHeight(NULL)` returns 0 |
| simply-sudoku | Menus in a look-alike font | `gfx.setFont(nil)` leaves the font unchanged |
| Night of the Bumblebee | Score in the system font | `setFontFamily(font)` with a font makes it the normal variant; `setFontFamily(nil)` does nothing |
| Orbeats | Score in the system font | `gfx.drawText`'s font family argument applies for that call |
| playdate-friction | Score digits one pixel left | `font:drawText` rounds fractional positions to nearest |
| music_box | Button symbols missing | `gfx.drawText` falls back to the system font's glyph for characters the font lacks; font methods do not |
| Funny Racer | A box after every arrow | Combining marks, U+200B and variation selectors have no glyph and no advance |
| combipool | Wrong face for `_*Goal*_` | Markup toggles one style at a time |
| PlayGB (C) | A line turned bold after `*` | C text functions have no markup |
| Roguelike Deckbuilder | Cards read "drawDescription" | Localized string tables (`.pds`) and `getLocalizedText` |
| music_box | Rename dialog | The CoreLibs keyboard's own font, images and sounds, supplied by the system |
| playdate-breakout | Crank indicator one pixel off | The SDK 3.1.1 crank indicator assets under `CoreLibs/assets/crank/`, supplied by the system |

### Files, assets and data

See [data/files.md](../data/files.md) and [data/json.md](../data/json.md).

| Game | What broke | What it needed |
| --- | --- | --- |
| games using the LDtk level library | Could not start | `gfx.imagetable.new` accepts the source file name, with or without extension and `-table-W-H` suffix |
| SDK example Mode7Driver | Stopped at load | An image compiled into `main.pdz` by `import 'track.png'` loads as `gfx.image.new('track')` |
| MissileCrank, playorama, Yonderu, PlayBook | Assets not found | On the device (3.1.2, by analysis) file names match ignoring letter case (games are usually made on macOS) |
| almost-tennis, pocket-pets, MissileCrank | Did not build on Linux | Their imports differ in case from the files (a build-side issue, not a runtime one) |
| hack-playdate-gallery | Stopped when opening its gallery | `listFiles` on a folder inside the bundle lists its entries relative to it, alphabetically, with "/" after subfolders |
| playnote-studio | Sample folder check failed | `isdir` and `stat` on directories, including bundle folders |
| Orbeats | Ran in an emulator but not in the Simulator | Compiled Lua modules are not files: `listFiles("/songs/")` is nil when only `songs.lua` exists |
| BlockDate | Themes failed | `file.load`/`file.run` of a separately compiled `.pdz` runs its own chunk and resolves its imports inside it |
| project_loose | Saves lost nested data | `datastore.write` writes nested empty tables as `[]` |
| archery | Error on save | `datastore.write` accepts a boolean or string |
| playdate-breakout | Save folder | An empty `bundleID=` stores data in a folder named after the bundle |
| SDK example MenuLocalization | Wrong data folder | `bundleID`, `imagePath` and `launchSoundPath` keys match ignoring case; trailing carriage returns are dropped |
| FactoryFarming (C) | Out of memory decoding a 632 KB world | C `json->decode` streams; it should not hold the whole input or every string |
| the playbit test suite | Open-file limit | At most 64 files open at once; one more `open` is nil with "Too many open files" |
| gamekid (C) | Host crash | `file->stat(path, NULL)` is used as an existence check |

### Lua runtime

See [lua/runtime.md](../lua/runtime.md) and [lua/objects.md](../lua/objects.md).

| Game | What broke | What it needed |
| --- | --- | --- |
| scene-based games (`home = import 'scenes/Home'`) | nil modules | The first `import` returns the file's values; any later spelling of the same file returns nothing and does not rerun it |
| the-kings-dungeon | Ran out of memory | The collector runs every frame for at least `setMinimumGCTime`; the game makes an image every frame |
| Yonderu, celeste | Stopped with a stray number as the error | Native calls inside a game's own coroutine return their values to that coroutine |
| sudokuPocket | "C stack overflow" in its generator | Coroutines get the full C-call budget |
| SDK example Exposure | Bad argument at load | The main chunk runs in a coroutine of its own; C Lua functions read the calling thread |
| celeste | Arithmetic on nil | Geometry field aliases (`rect.w`, `rect.h`, `arc.r`, ...) |
| cloudburst and others | CoreLibs behaved differently | CoreLibs runs when the game's `import` reaches it; geometry objects are userdata, so CoreLibs' `type(x) == "userdata"` checks pass |
| MissileCrank | Stopped in both environments | `pd.timer.new()` without a duration is refused by CoreLibs 3.1.1 (the game needed a patch to run anywhere) |
| moon-is-friend | "attempt to index a nil value (field 'scoreboards')" | `playdate.scoreboards` exists; offline, `getPersonalBest` calls back with an error before the next update |
| CoreLibs keyboard users | Re-entrant update | A saved `playdate.update` may be called re-entrantly by CoreLibs |
| untitled-roguelike | C stack overflow | A nested `gfx.sprite.update()` (from a subclass's `super.update`) does nothing |

### Input

See [system/input.md](../system/input.md).

| Game | What broke | What it needed |
| --- | --- | --- |
| BrickCrusher2020, project_loose | Moved 2.4 times too far at slow crank speeds | `getCrankChange()` returns the accelerated change as its second value: change / (1.04^(20 - abs(change)) + 0.2) |
| robbo-playdate, Cookie-Cranker, and most crank games | No crank movement | `getCrankChange()` works even when `playdate.cranked` is also defined |
| cloudburst | Ran a 5 fps low-power path | `getPowerStatus()` should report charging over USB (as the Simulator does) unless a battery is emulated |

### Audio

See [audio/players.md](../audio/players.md), [audio/synth.md](../audio/synth.md) and
[audio/sequences.md](../audio/sequences.md).

| Game | What broke | What it needed |
| --- | --- | --- |
| Orbeats | Notes never advanced; previews never faded | `fileplayer:getOffset()` reports the playback position, including the 0.25 s already buffered after `setOffset` |
| Orbeats | Title animation | `sound.getCurrentTime()` advances with the audio clock |
| Crazy Gravity | Silent music; a stalled video timebase | MP3 file players |
| Cascada (C) | Out of memory with a dozen tracks | File players stream; decoded audio must not be held in the game's heap |
| 13 C games (Spaceshipment, FactoryFarming, znax, tinytrek, ...) | No sound | C `sample->load` from compiled audio |
| Stellarator, playnote-studio | No sound | `newSampleFromData` samples, decoded again at play time |
| 1_bit_fantasy | Depends on sequence state for its music | Sequence tracks: `getTrackCount`, `getTrackAtIndex`, `track:getInstrument`, `getPolyphony` |
| any game that waits for a fade | Waits forever | `fileplayer:setVolume(..., fadeSeconds, callback)` fades and calls back |
| games that put sources on their own channels | Sounds twice as fast | A source belongs to at most one channel |
| SDK examples DrumMachine, MIDIPlayer | Screens follow the audio clock | MIDI loading and sequence timing |

### C API

See [c-api/calls.md](../c-api/calls.md) and [c-api/state.md](../c-api/state.md).

| Game | What broke | What it needed |
| --- | --- | --- |
| waternet | Crash | Menu item functions accept NULL |
| C games with menu userdata | NULL userdata | Userdata and context values are stored and handed back unchanged; any value works, including small integers |
| C games that call `calloc` | `calloc` faulted | A working heap, including `calloc` |
| ArduDate, PicoDate, RALA Ephemera | Faults, or leaks | Freed blocks are reused; the heap is at an executable address; a 128 KB DTCM exists |
| blips, znax, waternet | About 15 fps | API calls must be cheap; these games make many calls per frame |
| PlayGB | Busy-waits on `getElapsedTime` | Elapsed time must advance within a frame |
| SDK example Sprite Collisions | Walls offset | C sprite draw functions get screen coordinates; the sprite's position is not added again |

## How the Games Were Tested

All comparisons were black-box: the same game ran in the SDK 3.1.1 Linux Simulator (headless under Xvfb) and in the
emulator under test, and the screens were compared pixel for pixel. Nothing in a game's own code was changed except
where noted. The tools are in [tests/tools](../tests/tools/).

### Wrapping a Lua game

A wrapper is added without editing the game: the game's `main.lua` (or, for a built bundle, its `main` entry in
`main.pdz`) is renamed and imported by a small new `main.lua`. The wrapper intercepts `playdate.update`, including
later reassignments, and writes the display (`getDisplayImage`) to the data folder at fixed frames.

To make both environments deterministic, the wrapper also:
- replaces the clock functions with frame-based time (33 ms per frame) and pins `getSecondsSinceEpoch` and `getTime`;
- seeds `math.random` with a fixed value (both environments run Lua 5.4, and the same seed gives the same sequence);
- replaces `pairs` on tables whose keys are all strings or numbers with a sorted iteration, because string-key order
  follows a per-run hash seed in both environments;
- makes `playdate.drawFPS` a no-op and fixes `getFPS` at 30, since the real frame rate depends on host speed;
- optionally sets `playdate.isSimulator = nil` first, as on the device, for games that branch on it;
- passes re-entrant calls of a saved `playdate.update` through to the update in place before (CoreLibs' keyboard does
  this).

### Scripted input

The Simulator offers no input scripting that a test can rely on, so input is scripted from Lua inside the wrapper. It
replaces `buttonIsPressed`, `buttonJustPressed`, `buttonJustReleased` and `getButtonState` (accepting button
constants or names such as "a"), and delivers `AButtonDown`, `AButtonUp` and the other button callbacks to the top
pushed input handler or to `playdate`. The crank is undocked and turned at set rates, with `cranked` delivered and
`getCrankChange` replaced. Three scripts were used:
- A pressed at fixed frames (title screens into early gameplay);
- A, B, the d-pad and the crank over 600 to 900 frames (menus, long holds, the crank both ways);
- pseudo-random buttons from a fixed generator every 12 to 40 frames for 1500 frames, which reaches game-over screens
  and menus the fixed scripts never do.

Because the scripted `getCrankChange` replaces the real one, the crank's accelerated change is not exercised by these
runs; it was measured separately (see [system/input.md](../system/input.md)).

### C games

A C game is built twice from the same sources: for the host (`pdex.so`, run by the Simulator) and for the device
(`pdex.elf` with arm-none-eabi-gcc, run on the emulated CPU). A harness takes the place of the game's `eventHandler`
(renamed in a copy of the sources) and gives the game a copy of the API table with frame-based time, the same scripted
buttons and crank, and a frame dump every 75 frames. `rand` and `srand` are replaced with one generator so the host and
device C libraries agree. A game that busy-waits on `getElapsedTime` needs that clock to advance a little per call.

### Running and comparing

- Each environment runs for a fixed wall time, long enough to reach the last dump in both; slow debug builds of an
  emulator may need far longer than real time.
- The headless Simulator has no audio device, so its audio clock never moves (`getCurrentTime` stays 0, sounds never
  finish). Run the emulator without audio for the comparison, or give the Simulator an audio device and accept that
  rhythm games then differ for timing reasons alone.
- Give every wrapped game its own bundle ID. Two SDK examples share one, and their dumps overwrote each other.
- Read the bundle ID only from a line starting with `bundleID=`; some `pdxinfo` files are a single line with literal
  `\n` sequences.
- Tracing helps more than pixel diffs: logging `setFont` calls with a rendering fingerprint exposed two fonts with
  identical widths; logging timer firings and sprite positions to six decimals separated state differences from
  drawing differences.

### Differences that are not emulator bugs

When a difference remains, check these before changing the emulator:
- **`playdate.isSimulator`.** celeste draws 16 clouds when isSimulator is set and 4 when it is nil; project_loose
  shows a keyboard panel; playnote-studio's debug module replaces the game's background callback only in the Simulator.
- **Letter case.** The Linux Simulator's file system is case-sensitive; on the device (3.1.2, by analysis) names
  match ignoring case. playorama, Yonderu and PlayBook lose fonts and images in the Simulator only.
- **x86 against ARM builds of C games.** Spaceshipment's orbit drifts after about 600 frames (fused multiply-add and
  the ARM build's math library); playing-with-blocks gets a byte-reversed seed because the compilers evaluate
  `rand_next()` arguments in opposite orders; the SDK's C SpriteGame, Tilemap and SpriteCollisions call `rand()` several
  times inside one call's arguments.
- **Frame-rate readouts.** Games that print their own measured frame rate (One-Way-Out) differ in that readout, and
  everything after it on the line moves when its width changes.
- **Games that do not run in the Simulator.** C games without a Linux build of their native code cannot be compared
  there (Stream, SunriseClock, hopper, YouCannotGoBack and others); an emulator that runs a game the Simulator refuses
  (Orbeats without a `songs` folder, untitled-roguelike's `sprite.new(100, 20)`) is wrong, not better.
- **Simulator-only APIs.** `playdate.simulator.writeToFile` exists only in the Simulator; tests that save the screen
  with it fail on a device too.

## Open

These depend on behaviour that is not reproducible, or not yet settled:
- **`pairs` over object-keyed tables** follows memory addresses. Games that iterate such tables (or
  `allOverlappingSprites`, whose outer order also follows memory addresses; the SDK example "balls") can differ in
  order. The order is not stable and cannot be reproduced exactly.
- **SDK example drawSampled2** (tilted `drawSampled`): whole rows near source row boundaries sample a neighbouring row
  in the Simulator, while on the device (3.1.2, by analysis) these computations round once; only a device run can
  settle it.
- **Rotation sampling at small angles** (onebit frogger's logo at 0.24 degrees, 16 pixels): see
  [simulator-vs-device.md](simulator-vs-device.md).
