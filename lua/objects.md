# Native Objects in Lua

This file describes how Playdate objects appear to Lua code: which are userdata and which are tables, what their
metatables hold, what `type`, `pairs`, `rawget`, field assignment, `==` and `tostring` do with them, when two calls
return the same Lua value, and how geometry objects behave. The rest of the Lua environment is in
[runtime.md](runtime.md); objects created from C through the Lua C API are in
[../c-api/state.md](../c-api/state.md#objects-pushed-from-c). Everything here was measured in the Simulator (SDK
3.1.1) with `type`, a custom field assignment, `pairs`, `rawget`, `getmetatable` and `tostring` on every object type;
facts about the device (3.1.2, by analysis) are marked as such.

## Userdata or Table

| Objects | Kind | Notes |
| --- | --- | --- |
| Images, image tables, fonts, tilemaps | Userdata | |
| Geometry: rect, point, vector2D, size, lineSegment, arc, polygon, affineTransform | Userdata | Fields served by the class; always floats |
| Audio: synth, sample, sample player, file player, LFO, envelope, channel, sequence, track, instrument, effects, signals, and the rest | Userdata | |
| Files, pathfinder graphs and nodes, menu items, the system menu, video | Userdata | |
| Sprites (with or without CoreLibs) | Table | Custom fields allowed (needed for subclassing); `pairs` works |
| CoreLibs classes (timers, animators, and the rest) | Table | Plain Lua objects built by `class` |

For the userdata types:

- `type(obj)` is "userdata". Games and CoreLibs branch on this (CoreLibs accepts a geometry object in place of
  numbers by testing for "userdata").
- `pairs(obj)`, `next(obj)` and `rawget(obj, k)` raise errors.
- `getmetatable(obj)` returns the class table, with the class name in `__name` (for example
  "playdate.graphics.image").
- Copies keep identity: `table.deepcopy` of a table holding an image returns a table whose image *is* the original
  (`copy.img == data.img` is true), because userdata is copied by reference. A copied geometry object is likewise the
  same object, and shares later changes.
- Generic walkers (serializers, `inspect`, lume-style utilities) treat these values as opaque; they cannot see
  inside them.

An emulator that represents native objects as Lua tables gets every one of these wrong: type checks take the wrong
path, objects accept custom fields, `pairs` walks their internals and deep copies duplicate them.

## Fields: `__index` and `__newindex`

- **Reading an unknown field** gives nil.
- **Assigning a field** depends on the class (`tests/probes/newidx`):
  - Images, fonts, synths, files, graphs and most other native classes have no `__newindex`. Assigning any field is
    the error "attempt to index a playdate.graphics.image value" (with the class name).
  - `playdate.menu.item` and `playdate.pathfinder.node` have a `__newindex` that accepts their own settable fields
    and rejects others: "Could not set value for 'foo' on playdate.menu.item" (or `playdate.pathfinder.node`). A
    number key is named by its number (`'1'`), and a menu item's `callback` counts as unknown.
  - Geometry objects accept assignments to their documented fields and their aliases (below), and reject others.
  - Sprites take any field.
- **Geometry field aliases** (`tests/probes/rectq`), for reading and writing:
  - `rect.w` and `rect.h` are `width` and `height`; `size.w` and `size.h` likewise;
  - `lineSegment.x` and `lineSegment.y` are `x1` and `y1`;
  - `arc.r` is `radius`;
  - an arc keeps its direction in `clockwise` (there is no `direction` field).
- **Geometry fields are floats**, even when set from integers (`rect.x` reads 3.0 after `rect.new(3, ...)`), and
  `polygon:count()` is an integer.
- **The length operator** `#` on a geometry userdata raises an error unless its class defines `__len`.

## Metatables

- **Class tables** are the metatables. Each holds the methods (through `__index`), `__name`, `__gc` for classes
  that own native memory, `__eq` where objects compare by value, `__tostring`, and a `userval_count` number: the count
  of user values its objects carry (`tests/probes/uvcount`). Examples: image 2, sprite 4, tilemap 1, synth 6,
  fileplayer 8, sampleplayer 7, channel 6; 0 for the geometry types, fonts, files, signals and the menu.
- **`__gc`:** the image, image table, tilemap, file, sample, synth and font metatables have a `__gc`, and none has
  a `__metatable` field (`tests/probes/mtgc`, `tests/probes/fontgc`). A font that Lua drops is freed. The two signal
  classes (`playdate.sound.signal`, `playdate.sound.signalvalue`) have no `__gc` on the device (3.1.2, by
  analysis).
- **`setmetatable` on userdata** works (the Playdate's `setmetatable` accepts a table or a full userdata;
  `tests/probes/setmt`). Afterwards the object uses the new metatable: its methods are gone, `tostring` uses the new
  `__name`, and `setmetatable(obj, nil)` removes the metatable. A number gives "bad argument #1 to 'setmetatable'
  (table or userdata expected, got number)". The only protection is the usual `__metatable` field, which the native
  classes do not set.
- **Consequence:** a native object whose metatable is replaced loses its finalizer, so its native memory is never
  released (6,000 images grew the heap from 0.5 to 8 MB in `tests/probes/mtleak`). The same happens on the device
  (3.1.2, by analysis). An implementation must still check each object by its own type tag, not by its metatable, so
  that a swapped metatable cannot make one kind of object pass for another, and a foreign `__gc` that runs on the
  wrong object must refuse it without crashing.

## Equality

- Native objects compare by identity (`==` is `rawequal`) unless the class has `__eq`.
- **Geometry classes have `__eq`:** two arcs, rects, points and so on with equal fields compare equal
  (`tests/probes/arceq`). A method named `eq` is not the same thing; `arc1 == arc2` needs the metamethod.

## Identity: Which Calls Return the Same Value

One native object has one Lua value for as long as that value lives, with the exceptions below
(`tests/probes/identq`).

- **The same value each call:** `sprite:getImage()` (and it is the image given to `setImage`),
  `imagetable:getImage(n)` and `imagetable[n]`, `gfx.getFont()`, `getSystemFont()`, a font set with `setFont`, the
  sprites in `getAllSprites()`, pathfinder nodes, and `sequence:getTrackAtIndex`.
- **A new value each call:**
  - `gfx.getDisplayImage()` and `getWorkingImage()` (they are copies);
  - `image:getMaskImage()` (a new userdata that shares pixels with the mask);
  - `playdate.getSystemMenu()` (a userdata) and the items in `menu:getMenuItems()`, which are not the values
    `addMenuItem` returned;
  - an image put into an image table with `setImage` is not the value `getImage` returns later.
- **Pixels are shared regardless of identity:** an image in an image table, a sprite's image, a mask taken with
  `getMaskImage` and a mask set with `setMaskImage` share pixels with the original in both directions
  (`tests/probes/shareq`).
- Objects pushed from C follow their own rules (`pushBitmap` makes a new userdata each time; `pushObject` reuses
  one); see [../c-api/state.md](../c-api/state.md#objects-pushed-from-c).

## Sprites

- Sprites are tables whose metatable is the sprite class. They work without CoreLibs (all native methods, including
  `setSize`).
- `gfx.sprite.update()` (update all sprites) and the default `sprite:update()` are the same field. Called on a
  sprite without its own update function, or with any other argument, it updates and draws every sprite; called again
  from inside a sprite update (a subclass's `super.update`, a draw callback or the background callback), it does
  nothing, so `Class.super.update(self)` is safe (see [../graphics/sprites.md](../graphics/sprites.md)).
- `sprite:copy()` copies the custom Lua fields.
- A sprite pushed from C has the sprite methods in Lua.

Sprite behaviour is in [../graphics/sprites.md](../graphics/sprites.md).

## Other Classes

- **Channel signals:** `channel:getDryLevelSignal()` and `getWetLevelSignal()` return `playdate.sound.signalvalue`
  objects. That class has only `getValue`. They can still be used as modulators (`synth:setAmplitudeMod`). See
  [../audio/effects.md](../audio/effects.md).
- **The system menu** (`playdate.getSystemMenu()`) is a userdata, and its items are `playdate.menu.item` userdata.
- **`playdate.debugDraw`** is a callback, nil until the game defines it.

## `tostring` and Addresses

- `tostring` of a native object gives its class name and an address ("playdate.pathfinder.node: 0x55f9b23dcef8" in
  the Simulator).
- Geometry objects print their fields: a line segment prints with two spaces between its points; an
  `affineTransform` separates its columns with tabs.
- **Addresses:** `tostring` of a table, function, thread or userdata, and `string.format("%p", v)`, show the object's
  address. On the device (3.1.2, by analysis) that is a 32-bit value printed as `0x` and unpadded lowercase hex
  (check on hardware; `tests/probes/heapaddr`). The Simulator prints 64-bit host addresses
  (`table: 0x555fdf186ac0`). The type labels, the width and flag handling of `%p` (`[%20p]` pads with spaces) and
  `(null)` for values without an address are the same. An emulator should print emulated addresses, so that no game
  sees a value outside the 32-bit range; values with no emulated address (a native function) can show their low 32
  bits.

## Implementation Notes

A reimplementation has two reasonable ways to give geometry objects the userdata behaviour:

- **Native userdata** with fields served by `__index` and `__newindex`: matches the device and is fast for code
  that makes many small rects and points.
- **Opaque tables:** keep geometry as Lua tables (written in Lua) and teach the Lua core to treat a table whose
  metatable carries a marker as userdata: `type` returns "userdata"; `next`, `pairs`, `rawget`, `rawset`, `rawlen` and
  the table library refuse it; assigning a field it does not have is an error. Constructors must set the metatable last.
  Known gaps of this approach: `#` still returns the table length (close it in the length operator); a field set to nil
  cannot be set again (the new-field check sees it as new); the marker field is visible on the class; and C code using
  `lua_type` still sees a table, so the Lua C API must report these as objects separately.

Other native objects are best kept as full userdata holding the native pointer and a type tag, with the class table
as the metatable, and a weak registry from native pointer to Lua value to keep one Lua value per object. Light
userdata cannot carry a per-type metatable, so it is not an option.
