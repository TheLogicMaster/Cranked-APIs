# State Between C and Lua, and the Lua C API

This file describes which drawing state a game's C code and its Lua code share and which each keeps for itself
(draw mode, font, tracking, line caps, background color, contexts), how the context stack behaves from each side, and
the Lua C API (`pd->lua`) that hybrid games use to register functions and classes, read arguments, push values and
objects, and call Lua. Calling conventions and callbacks are in [calls.md](calls.md); how native objects look to Lua
code is in [../lua/objects.md](../lua/objects.md). Measurements are from the Simulator (SDK 3.1.1) with hybrid probe
games; facts about the device (3.1.2, by analysis) are marked as such.

## Separate and Shared Drawing State

Measured with `tests/probes/modeq` and `tests/probes/ctxq`:

| State | C and Lua |
| --- | --- |
| Image draw mode (`setDrawMode` / `gfx.setImageDrawMode`) | Separate |
| Font (`setFont` / `gfx.setFont`) | Separate |
| Text tracking (`setTextTracking` / `gfx.setFontTracking`) | Separate |
| Line cap style (`setLineCapStyle` / `gfx.setLineCapStyle`) | Separate |
| Background color (`setBackgroundColor` / the color Lua's `gfx.clear()` uses) | Separate |
| Context stack (`pushContext` / `popContext`) | Each side saves and restores only its own settings |
| Draw offset | Shared |
| Clip rect | Shared |
| Stencil | Shared |
| Drawing target (the screen, or a pushed image) | Shared |

- A C call that sets one of the separate settings does not change what Lua reads back
  (`gfx.getImageDrawMode()` still returns Lua's mode), and the other way round. The SDK's Particles example draws its
  Lua text in Lua's Copy mode although its C code set Inverted.
- C `getTextWidth(font, text, len, encoding, tracking)` uses its tracking argument only, never the tracking set
  with `setTextTracking` or Lua's tracking.
- Text leading (`setTextLeading` in C, the leading arguments in Lua) was not measured for sharing.
- C drawing calls take their color and line width as arguments, so Lua's `setColor` and `setLineWidth` do not
  apply to them.
- C text has no `*bold*` and `_italic_` markup and uses the current C font alone; Lua's `gfx.drawText` switches to the
  bold and italic fonts of the Lua font family. See [../graphics/text.md](../graphics/text.md).
- **Default font:** C `setFont(NULL)` selects the system font. Lua `gfx.setFont(nil)` (or no argument) leaves the
  font unchanged.

## Contexts

- **C `pushContext(NULL)`:** the target is the display frame buffer, with the screen's own clip rect and draw offset;
  drawing settings such as the color carry over (documented; on the device (3.1.2, by analysis)). A common mistake is to
  copy the current context, target included: a game that pushes an image, then the screen, then draws the image would
  draw into the image itself.
- **Lua `gfx.pushContext()` without an image** keeps the current target.
- **`pushContext(image)`** (either side) keeps line width, color, tracking and draw mode, starts with a draw offset of
  (0, 0), and clips to the image. `gfx.clear(color)` then clears the image.
- **`lockFocus(image)`** is a `pushContext(image)` marked as a focus context (on the device (3.1.2, by analysis);
  measured in `tests/probes/ctxq`). Any focus contexts on top are popped first, so calling `lockFocus` twice does not
  nest. Inside it the draw offset is 0 and the clip rect is the image. nil is allowed; anything else that is not an
  image is a type error. A `pushContext(image)` inside it draws into the pushed image.
- **`unlockFocus()`** pops the top context only when it is a focus context, and restores every setting changed since.
- **`popContext()`** refuses a focus context, and with nothing pushed raises "no pushed context!".
- **Display scale:** at `display.setScale(n)` the screen context is the top-left (400 / n) by (240 / n) of the frame
  buffer, also after `clearClipRect`; see [../graphics/display.md](../graphics/display.md).

## The Lua C API (`pd->lua`)

### Registration

- Register C functions and classes in the event handler at `kEventInitLua` ([calls.md](calls.md#the-event-handler)),
  then call them from `main.lua`.
- `addFunction(f, name, &err)` makes `f` callable from Lua under `name`; `registerClass(name, reg, vals, isstatic,
  &err)` makes a class table with methods and constants.
- **Calling thread:** a registered C function reads its arguments from, and pushes its results to, the Lua thread
  that called it: the main chunk's coroutine, the update coroutine, or a coroutine of the game's own
  (`tests/probes/coroq2`). Reading the default thread instead gives errors such as "bad argument #1 (image expected,
  got thread)".
- The function returns the number of results it pushed, as a `lua_CFunction` does.

### Reading arguments

- **Positions are checked** (on the device (3.1.2, by analysis); measured in the Simulator, `tests/probes/luac`).
  `getArgType`, `getArgInt` and the other `getArg*` functions, `getBitmap` and `getSprite` raise a Lua error for a bad
  index. The device's messages:
  - 0, or below the bottom of the stack: "invalid index at lapi.c:65";
  - past the room the C function has (its arguments plus 20 slots, so 30 with two arguments): "unacceptable index at
    lapi.c:60";
  - an upvalue index past 256: "upvalue index too large at lapi.c:72".

  The Simulator's build shows the checked expression instead of these messages. The registry index, and upvalue
  indices up to 256, read as values (nil for upvalues).
- **Types:** `getArgType` reports `kTypeObject` for native objects (images, sprites, geometry objects and the rest)
  and gives their class name. Geometry objects are objects here, not tables.
- **Conversions:** the numeric getters (`getArgInt`, `getArgFloat`) convert a string argument that holds a number,
  as `lua_tonumber` does.
- **Wrong types:** `getBitmap` on an argument of another type raises a Lua argument error rather than returning
  NULL.
- `getArgBytes(pos, &len)` returns the string's bytes and length.

### Objects pushed from C

Measured in `tests/probes/luac`:

- **`pushObject(ptr, type, nValues)`** of a pointer that already has a live userdata pushes that same userdata
  (`rawequal` holds). When the class asked for differs, it gives no handle.
- **Handles are stable:** the `LuaUDObject` handle names its userdata for as long as the userdata lives, so C code can
  keep it between calls and use `retainObject` and `releaseObject` later. A handle is not a stack index.
- **User values** (`setUserValue`, `getUserValue`) always read back as nil, whether the value was passed as an
  argument or pushed just before `setUserValue` (the same on the device (3.1.2, by analysis)).
- **`pushBitmap`** makes a new userdata on every push, so two pushes of one bitmap are neither `rawequal` nor `==`;
  each holds its own reference, released by its `__gc`.
- **`pushSprite`** pushes the sprite's one Lua value (a table), with the sprite methods available.
- Class tables carry a `userval_count` number; see [../lua/objects.md](../lua/objects.md#metatables).

### Calling Lua

- `callFunction(name, nargs, &err)` calls the named Lua function with the `nargs` arguments pushed before it.
- `callFunction_deprecated(name, nargs)` also calls the function (it is not a no-op). An implementation trap: the
  function has to be placed below the already pushed arguments before the call, not pushed above them.
- `indexMetatable()` (inside a class's `__index` implementation) looks the key up in the metatable: methods, computed
  fields, class constants, and nil for missing fields, as in the Simulator.

### Memory

Lua uses 32-bit numbers and pointers on the device (3.1.2, by analysis), and Lua shares the 16 MB heap with C
allocations; see [../lua/runtime.md](../lua/runtime.md#garbage-collection-and-memory).
