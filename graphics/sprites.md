# Sprites

This file covers the Playdate sprite system as games see it: creating sprites, their images, size, scale and
rotation, the display list and draw order, the update pass and draw callbacks, the dirty-rect redraw (including the
dirty areas made by drawing straight to the screen), opacity and occlusion, clip rects and stencils, the background
callback, tilemaps (on sprites and as objects), sprites without CoreLibs. Collide rects, collision responses, queries and the geometry types are in
[collisions.md](collisions.md). Shape rasterization is in [drawing.md](drawing.md), image operations (rotation,
scaling, masks) in [images.md](images.md), and the Lua object model in [../lua/objects.md](../lua/objects.md).

Unless noted, behaviour was measured in the Simulator (SDK 3.1.1). Rules that are also known to hold on the device
(3.1.2, by analysis) say so. Probes are cited as `tests/probes/<name>`.

## Sprite objects

- **Sprites are Lua tables**, not userdata, in the Simulator (SDK 3.1.1) and on the device (3.1.2, by analysis). They
  take any custom field (needed for CoreLibs subclassing), and `pairs` works on them. `playdate.graphics.sprite` has a
  `userval_count` of 4 (`tests/probes/uvcount`).
- **No CoreLibs needed.** `gfx.sprite.new` and the sprite methods are native, so sprites work without importing
  `CoreLibs/sprites`; the sprite class has its own `__index`. `setSize` is native too. What CoreLibs adds are Lua
  helpers such as `setBackgroundDrawingCallback`, `addEmptyCollisionSprite` and `addWallSprites`; these are nil until
  the game's `import` of `CoreLibs/sprites` runs (`tests/probes/preimp`). There is no `spritelib` global.
- **Identity:** a sprite keeps one Lua value. `getAllSprites` returns the same values each call, and a C
  `pushSprite` of the same sprite pushes that same value (unlike `pushBitmap`, which makes a new userdata each time).
  A sprite pushed from C has the normal sprite methods.
- **Booleans:** `isVisible`, `updatesEnabled` and `collisionsEnabled` return `true` or `false`, not 0 or 1. (0 is
  truthy in Lua, so returning integers breaks `if not s:isVisible()`.)
- **Floats:** `getGroupMask` and `getCollidesWithGroupsMask` return floats.

### `gfx.sprite.new([image or tilemap])`

Accepts nothing, nil, an image, or a tilemap. Anything else is the error "bad argument #1 to 'newfunc' (image or
tilemap)" (for example `gfx.sprite.new(100, 20)`, which stops one game at load in the Simulator).

### `copy()`

Copies position, z-index, tag, visibility, collide rect, the same image (not a copy of it), and the sprite's custom
Lua fields. If the original is in the display list, the copy is added too.

## Image, size, scale and rotation

### `setImage(image, [flip, [scale, [yscale]]])`

- Without a scale argument, the sprite keeps its current scale (it is not reset to 1, and not set to 0).
- Setting the image the sprite already has, with the same scale, does not redraw it from C. From Lua it redraws the
  sprite when the image was drawn into since the sprite last drew it (a game that redraws its score image during its
  update and sets it again sees the new score at once).
- Setting another image sets the sprite's opaque flag from that image (see "Opacity and occlusion"). No image clears
  the flag.
- A tilemap does not replace the image: after `setTilemap`, `getImage` still returns the image (see "Tilemaps on
  sprites").
- `getImage()` returns the same value each call, the one that was given.
- C `getImageFlip` of a sprite without an image is unflipped.

### Size

- The size is the image size times the scale, truncated per axis: `setScale(1.5)` on a 21 by 15 image gives 31 by
  22; an 8x6 image at scale (2, 3) is 16 by 18. Bounds follow from the center: at position (40, 30) with the default
  center the corner is (24.5, 19) (`tests/probes/sprscale`).
- `setSize(w, h)` truncates: 20.5 by 14.3 is 20 by 14, 10.6 by 5.5 is 10 by 5 (`tests/probes/fracargs`).
- Positions are not rounded: `moveTo(1.6, 2.4)` keeps both fractions. The default center is (0.5, 0.5).
- The area a sprite draws in, and the area the update clears for it, is its size measured from its floored corner.
  A sprite at x = 24.5 and 31 wide covers columns 24 to 54 (`tests/probes/sprclr`). (A common mistake is to round the
  far edge up separately, which clears one column and row too many at fractional positions.)
- The collide rect is not scaled, and does not flip with the image (a collide rect on the left half stays on the
  left after `setImageFlip(kImageFlippedX)`).

### Rotation

- `setRotation(angle)` stores the angle reduced to [0, 360): -15 reads back as 345, -90 as 270, 360 as 0
  (`tests/probes/sprrotq`).
- The sprite turns about its center point (`setCenter`), which stays at the sprite's position. With center (0.5, 1),
  a gun pivots at its base.
- The size becomes the rotated image's size: 90 degrees swaps width and height; other angles give the rotated
  bounding box (14 by 13 for a 12 by 6 image at 45 degrees).
- Placement: the bounds' middle is the position minus the rotated offset of the center point from the image middle:

      middle = position - rotate(((cx - 0.5) * w, (cy - 0.5) * h), angle)

- Drawing is exactly `image:rotatedImage(angle, scale)` drawn at the bounds rounded down (36 of 36 cases). An opaque
  image therefore keeps black uncovered corners only where `rotatedImage` keeps them (see [images.md](images.md)).

### Scale and flip in drawing

- A sprite with a scale draws a scaled copy of its image (as `image:scaledImage`), with its flip, at its bounds
  truncated toward zero. Drawing through `drawScaled` at the fractional position instead places a trimmed image's
  stored rows differently: one row lower for a sprite partly above the screen (`tests/probes/sprscq`).
- A sprite with both a scale and a flip draws its scaled image flipped (`tests/probes/sprflipscl`, 17 cases).
- A Lua sprite with a rotation or scale draws a rotated or scaled copy, and that copy becomes the sprite's bitmap for
  opacity purposes (see below).

Open point: for negative positions, "rounded down" (rotation, draw area) and "truncated toward zero" (scaled copy)
differ; the measurements were made with the wording given here, but not every case was checked at negative
coordinates.

## The display list and draw order

The display list is kept sorted by z-index. `gfx.sprite.getAllSprites()` returns it in that order
(`tests/probes/allspr`, `tests/probes/sprdiff2`):

- lowest z first;
- within one z, the order sprites were added;
- a sprite removed and added again goes to the end of its z group;
- `setZIndex` with a new value moves the sprite at once to the end of its new z group, and marks its area dirty;
  with the same value it does nothing, so the sprite keeps its place.

```
insert(list, s):
    put s after the last sprite whose z <= s.z (at the front if there is none)
setZIndex(s, z):
    if s.z == z: return
    s.z = z
    if s is in the list: remove s, insert(list, s), mark its area dirty
```

Drawing and updating both follow this order. C `setZIndex` and the Lua method behave the same.

## The update pass

`gfx.sprite.update()` (C `updateAndDrawSprites`) first calls each sprite's update function, then redraws.

- **Order:** z order, add order breaking ties (the display list order above) (`tests/probes/updord`).
- **Added during the pass:** a sprite added by another sprite's update is first updated in the next pass.
- **Removed during the pass:** a sprite removed by an earlier sprite's update is still updated in the same pass.
- **Arguments are ignored.** `gfx.sprite.update` and the default `sprite:update` are the same field. Called as
  `s:update()` on a sprite without its own update function, or with any other argument, it updates and draws every
  sprite, as `gfx.sprite.update()` does (`tests/probes/sprupq`). Some games never call `gfx.sprite.update()` and rely
  on this through one sprite's `update`.
- **Re-entry does nothing.** A call to `gfx.sprite.update()` (or C `updateAndDrawSprites`) made during an update, from
  a draw function, or from the background callback, returns at once (`tests/probes/sprre`). So a subclass's
  `Class.super.update(self)` is safe, and a background callback that ends up calling `sprite.update()` does not
  recurse.
- `setUpdatesEnabled(false)` skips the sprite's update function.
- C `setUpdateFunction` works in a C-only game (no Lua state is needed).

## Redrawing: dirty rects

`sprite.update()` redraws only dirty areas. With nothing dirty, nothing is drawn: with no sprites, the screen is
left alone even after `setBackgroundColor`.

### What makes an area dirty

- A sprite that moved, resized, changed image, z-index, visibility, draw mode, flip, opaque flag, clip rect or
  stencil, was added, was removed, or was marked dirty (`markDirty`).
- `gfx.sprite.addDirtyRect(x, y, w, h)` (C `addDirtyRect`).
- `setAlwaysRedraw(true)`: the whole screen every frame.
- Drawing into a sprite's image, or changing its tilemap's tiles (see "Image and tilemap changes").
- Drawing straight to the screen, once any sprite exists (see "Direct drawing marks the screen dirty").

`setImageDrawMode` and `setImageFlip` (C `setDrawMode`, `setImageFlip`) mark the sprite dirty only when the value
changes. This holds whether the call comes before `sprite.update()` or from the sprite's own update function
(`tests/probes/sprmode`). Changing the clip rect redraws the sprite (a game can reveal an icon by growing its clip
rect every frame).

### Which area a change dirties (on the device (3.1.2, by analysis); the Simulator matches)

Each sprite remembers the area it drew: the union of what it drew since it last changed, where the first draw after
a change replaces the old area. When the sprite changes, that remembered area becomes dirty, not its old bounds. A
sprite that showed only its right half beside an opaque sprite clears only that half. Removing a sprite dirties the
area it drew.

The new bounds are then cut by each opaque sprite above it, using the area that sprite drew last
(`tests/probes/occl2`):

- if the rect sticks out on one side and the occluder spans it in the other direction, only the part outside is kept;
- a rect inside the occluder is dropped;
- the left-side rule sets the rect's right edge to the occluder's left edge even when the rect ends short of it, so
  a sprite moved just left of an opaque sprite dirties the gap up to it, and sprites in that gap redraw;
- a tilemap sprite above cuts the rect too: when the rect lies inside the map, it shrinks to the bounding box of the
  tiles under it that are empty or masked, and is dropped if there are none (`tests/probes/tmoccl`);
- a hidden sprite cuts nothing (`tests/probes/occl3`).

### `sprite->markDirtyRect` (C, SDK 3.1)

For a sprite in the display list, the rect, relative to the sprite's bounds, becomes a dirty rect: x runs from
trunc(bounds.x) + trunc(rect.x) for trunc(rect.width), and the same for y. A sprite not in the list is ignored. The
next update redraws that area, and the C draw callback gets it, clipped to the sprite (`tests/probes/sprdirty`).

### Which dirty rects merge (on the device (3.1.2, by analysis); the Simulator matches)

A new dirty rect merges with an existing one (into their bounding box) when they overlap, or when they continue each
other exactly: side by side with the same top and bottom, or stacked with the same left and right. Rects that touch
along only part of an edge, or at a corner, stay separate (`tests/probes/dirtyq`). So a sprite moved by exactly its
width is redrawn as one rect.

Each remaining rect is redrawn on its own, with one background callback each (a scrolling scene measured three calls
in one frame). Taking the union of all dirty rects is wrong.

### Redrawing a rect

```
for each dirty rect R:
    if a visible sprite covers R (see occlusion): start drawing from that sprite, skip the background
    else: fill R with the background colour, or run the background callback for R
    for each visible sprite touching R, in display-list order (from the occluder, if any):
        clip to R, the sprite's own bounds, and the sprite's clip rect; apply its stencil
        draw its image or tilemap with its own draw mode, or call its draw function
```

- **Clipped to the sprite's bounds.** A sprite's drawing never leaves its own bounds, even when the dirty rect is
  larger (a merged rect can be much larger than one sprite). A text box drawing its border half outside the sprite
  shows only the inner half.
- **The live list.** The drawing pass follows the live display list (`tests/probes/spradddraw`). If a draw function
  removes another sprite and adds a new one, the new sprite is drawn in the same pass if its z-index is above the
  sprite being drawn and it overlaps the rect; the removed sprite is not drawn; and neither change leaves a dirty
  rect for the next frame. A sprite that replaces an icon sprite on every draw is therefore drawn once, not every
  frame.
- **Draw callbacks run only when needed**: for sprites touching a dirty rect. `markDirty` causes exactly one more call.

## Draw callbacks

### Lua `draw(x, y, width, height)`

- The rect is the redrawn part in sprite-local coordinates: the screen rect minus the sprite's position rounded
  down, clipped to the sprite's own size and cut by its clip rect. A full redraw passes (0, 0, w, h); a partial one
  only the dirty part, such as (10, 10, 5, 5).
- Example: a 57-pixel-wide sprite centered at x = 200 sits at x = 171.5 and covers 58 screen columns, but a full
  redraw passes 0, 0, 57, 30. Games often draw their whole sprite from these values, so passing 58 makes buttons a
  pixel wider.
- The draw offset is not taken out of the rect: with a global draw offset of 5, a sprite at x = 0 is called with
  x = 5 (`tests/probes/occl`).
- While the callback runs, the draw offset is the sprite's truncated position plus the global offset (only the
  position for a sprite that ignores the draw offset).
- The callback runs with the current global image draw mode, not the sprite's own (`setImageDrawMode` applies to the
  sprite's image or tilemap only). A game that sets `kDrawModeNXOR` globally and draws white text in a callback
  relies on this. A sprite with its own draw function is not affected by its image draw mode.

### C draw functions

- The function receives the sprite's bounds and the draw rect, both in screen coordinates: (5, 6, 10, 8) twice for a
  10 by 8 sprite at (5, 6).
- The draw rect is clipped the same way as in Lua: a 100 by 60 sprite at (70.5, 60.25) gets 70, 60, 100, 60
  (`tests/probes/sprdirty`).
- The sprite's position is not added to the draw offset for a C draw function: it draws in screen coordinates.
  (Adding it puts walls drawn by such a function off by their own position.)
- The draw-mode rule is assumed to be the same as in Lua.

## Image and tilemap changes

Drawing into the image a sprite shows (through `pushContext` or `lockFocus`), or `image:clear` on it, redraws the
sprite on the next update without `markDirty` (`tests/probes/clipdirty`). The same holds for its tilemap:
`setTileAtPosition` or `setTiles` redraws the sprite (`tests/probes/tmdirty`).

When the change shows depends on when it was made (`tests/probes/sprimgupd`, `tests/probes/sprimgpart`,
`tests/probes/tmupd`):

- **before `gfx.sprite.update()`:** shown that frame;
- **after it:** shown the next frame;
- **during the update** (in the sprite's own update function or another sprite's): not noticed in that update. Any
  redraw of the sprite afterwards, even a partial one inside another sprite's dirty rect, counts as having seen the
  change. So a sprite that redraws its image in its update every frame shows the latest image every other frame,
  and one that is also partly redrawn every frame by a moving sprite never shows the change outside that area;
- **with `markDirty()` in the update as well:** shown every frame;
- **tilemap tile changes** show at once, even when made during the update.

One way to model this: record each image's change counter when the update begins, compare against it when deciding
what is dirty, count any redraw as having seen it, and check tilemaps at drawing time. `getDisplayImage` always
returns the previous frame (`tests/probes/disppl`), so this is the sprite system, not display timing.

## Direct drawing marks the screen dirty

Once any sprite has been created, each drawing call made straight to the screen (not into an image, and not by the
sprite system itself) adds its bounds as a dirty rect. The next `sprite.update()` fills that area with the
background and redraws the sprites over it, so text or shapes a game stops drawing disappear
(`tests/probes/stale`, `stale2` to `stale4`, `tests/probes/dirtyb`).

- **Before the first sprite:** nothing is tracked. A game that never calls `gfx.sprite.new` (or C `newSprite`) can
  call `sprite.update()` without anything being erased. Creating one sprite, even one never added, starts the
  tracking for good; removing every sprite does not stop it.
- **During sprite drawing** (in a draw function or the background callback) drawing adds nothing.
- Drawing entirely off screen, or into an image, adds nothing. Two separate calls give two separate rects (then
  merged by the rule above).

The bounds are the shape's, not its pixels', clipped to the clip rect and the screen, after the draw offset:

| Call | Dirty rect |
| --- | --- |
| `fillRect(50, 60, 30, 20)` | 50, 60, 30, 20 |
| 1-pixel line | the end points' box, inclusive (20,30 to 120,90 gives 20, 30, 101, 61), even where the line has no pixels |
| wide line | the box of the line's quad corners, inclusive, united with the round caps' rects; a zero-length wide line dirties only its caps (none with butt or square caps) |
| pixel | 1 by 1 |
| ellipse outline, arc | the rect |
| filled ellipse (and outlines wide enough to be filled) | x to x + 2 * (w >> 1) + 1, one pixel wider (and taller) than the rect for even sizes |
| polygon, triangle | the vertices' box, inclusive |
| `drawRect`, 1 pixel | the rect |
| `drawRect`, wider strokes (any stroke location) | the stroke's outer box plus one pixel right and down |
| `drawRoundRect` | the rect only, even when a centered or outside stroke extends past it |
| `gfx.clear()` | the clip rect (the whole screen when nothing is clipped); `clear` fills only the clip rect |
| image | the rect of its stored pixels as pdc trimmed them (pdc rounds the trimmed left edge down to a multiple of 8), mirrored by flips and scaled by `drawScaled`; images made at runtime give their full size |
| text | per glyph, its stored pixels' left, right and top, extended down to the bottom of its line: "A" at y = 100 in the system font gives 100, 101, 9, 19; "A\nB" gives a height of 39; a space gives none |
| a glyph image (`font:getGlyph("A"):draw`) | its stored rect only (100, 101, 9, 14) |

Example of the shape rule: a line from (-10, -5) to (190, 145) dirties rows 0 and 1, though it first appears on row
3. A zero-length wide line has length 0 in the quad formula (on the device (3.1.2, by analysis) the quad is empty);
guard the zero length: computing the quad from it gives huge corners that dirty the whole screen.

A game that draws every frame but never updates sprites grows the dirty list without limit; collapsing a long list
into its bounding rect is a reasonable implementation choice (not measured).

## Opacity and occlusion (on the device (3.1.2, by analysis); the Simulator matches)

- **Default:** a sprite whose image has no transparency (no mask, nothing trimmed) is opaque; one with a mask is not.
  An image compiled from a PNG without transparency has no mask.
- **`setImage`** with another image sets the flag to that image's opacity; no image clears it.
- **`setOpaque`:** a change of the flag marks the sprite dirty.
- **`setTilemap`** leaves `isOpaque()` as it was (`tests/probes/opq`).
- **Stencils:** for games built with SDK 3.0.100 or later (`pdxversion` above 30099), setting a stencil makes the
  sprite not opaque, and clearing it gives an image sprite its image's opacity back. Older games keep the flag.
- **Rotation and scale:** a Lua sprite with a rotation or scale uses the rotated or scaled copy as its bitmap, so its
  opacity is the copy's: false at angles other than right angles (the rotated copy has a mask), unchanged at right
  angles and for scaling. Back at no rotation and scale 1, the original image's opacity returns
  (`tests/probes/rotopq`).
- **Occlusion:** before drawing a dirty rect, the system looks from the top for a visible sprite that covers the
  whole rect. An image or callback sprite covers it when it is opaque and its screen bounds, cut by its clip rect,
  contain the rect. A tilemap sprite covers it when every tile under the rect is an opaque image, whatever its opaque
  flag. When one covers the rect, the sprites below it are not drawn, their draw callbacks do not run, and the
  background is not filled (`tests/probes/occl`).

A consequence that games can see: a full-screen overlay that is opaque for the first frames hides the background
callback, so the callback first runs when the overlay goes, and any `math.random` calls it makes move with it
(`tests/probes/bgfirst`).

## The background

- Without a background callback, each dirty rect is filled with `gfx.setBackgroundColor`'s colour.
- CoreLibs' `gfx.sprite.setBackgroundDrawingCallback(fn)` makes a full-screen sprite that ignores the draw offset
  and calls `fn(x, y, w, h)` once per dirty rect. Inside it `getDrawOffset()` returns 0, 0 while the
  camera is scrolled, and text drawn there stays put (`tests/probes/sprbgq`).
- `gfx.clear()` and other drawing inside the callback dirty nothing, so a callback that clears does not make every
  later frame a full redraw. `clear` there fills only the clip rect.
- The callback is skipped for rects an opaque sprite covers (above).

## Ignoring the draw offset

A sprite with `setIgnoresDrawOffset(true)` draws, and runs its draw callback, with only its own position as the
offset. Its image and tilemap are drawn at its own position, not at the screen's top-left (a common mistake is to
pass "ignore the draw offset" down to the bitmap drawing, which then drops the sprite's position too).

## Clip rects and stencils

### `setClipRect(x, y, w, h)` and `clearClipRect`

- The clip rect is in screen coordinates and applies while the sprite draws.
- Changing it redraws the sprite.
- An empty clip rect hides the sprite: a zero height, or a rect that does not touch the sprite, draws nothing. Only
  `clearClipRect` removes clipping, so "no clip rect" needs its own flag (an all-zero rect is a valid, empty clip).
- Fractional values (Lua): the origin rounds down and the size rounds up, each on its own. A clip of
  (x + 0.6, y + 0.6, 10, 10) covers pixels 0 to 9 from x, and a height of 1.4 covers 2 rows (13 rects sampled).
- `setClipRectsInRange` (Lua and C) follows the same rules.
- `clearClipRectsInRange` in the SDK 3.1.1 Simulator stops the game when the display list is empty after sprites
  were removed, or holds sprites no update has drawn yet: the console shows
  `LCDSprite_getBounds: non-NULL value required for argument 's'` and no later update runs. With sprites the last
  update drew it works, and so does a call before any sprite exists (`tests/probes/sprclipclr`). Whether the device
  does the same is not known yet; an emulator can keep running.

### Stencils

- Drawing passes only where the stencil pixel is white; black and clear pixels both block (`tests/probes/stencil`).
- `gfx.setStencilImage` raises "stencil images must be at least 32 pixels wide" for a narrower image;
  `sprite:setStencilImage` does not check.
- `sprite:setStencilPattern` accepts the same forms as `gfx.setStencilPattern` (a table of eight rows, eight row
  numbers, or a level with an optional dither type, Bayer 4x4 by default) and builds the same patterns
  (`tests/probes/stpat`, `tests/probes/stpat2`); see [drawing.md](drawing.md).
- An untiled stencil's bounds are checked in target coordinates, after the draw offset.

### Draw mode

`sprite:setImageDrawMode` applies when the sprite's image or tilemap is drawn (fill white, XOR and so on), not the
context's mode. It does not apply inside the draw callback (see "Draw callbacks").

## `moveTo(point)` and positions

`moveTo` also accepts a `playdate.geometry.point`, as returned by `animator:currentValue()`. This is not documented
but is used by games. `moveTo(x, y)`, `moveBy`, `setBounds`, `setCenter`, `getPosition` and the rest behave as
documented.

## Tilemaps on sprites

- `setTilemap(map)` makes the sprite draw its map. A sprite without an image takes the map's pixel size; one with an
  image keeps the image (still returned by `getImage`) and its size.
- The opaque flag is unchanged by `setTilemap`.
- Tile changes redraw the sprite, at once even during the update.
- A tilemap sprite occludes by its tiles, and cuts dirty rects below it by its tiles (see above).
- A tilemap sprite never takes part in alpha collisions ([collisions.md](collisions.md)).

## Tilemap objects

The storage, `setSize`, `setTileAtPosition` and `setTiles` rules are the device's (3.1.2, by analysis). The empty-tile
values, C positions and integer sizes were measured in the Simulator.

- **Storage:** tiles behave as if stored as `(index - 1) & 0xFFFF`, so index 0 is stored as 0xFFFF and means empty.
- **Lua indexes** are 1-based, with 0 empty. `getTileAtPosition(x, y)` (1-based positions) returns nil outside the
  map and for an empty tile, otherwise the stored value plus 1 (so index -1 reads back as 65535). `getTiles` returns
  the data and the width, with stored plus 1 for every tile, so an empty tile reads as 65536.
- **C positions** are 0-based for both `getTileAtPosition` and `setTileAtPosition`. An empty tile reads as 65535.
- **`setSize(w, h)`** truncates fractional sizes and empties every tile, including tiles set before.
- **`setTileAtPosition`** ignores a position outside the map. Each coordinate is checked on its own, so an x past the
  width does not reach the next row.
- **Lua `setTiles(data, width)`** sets the size to `width` by `ceil(#data / width)`, empties it, then sets position
  `k - 1` (row-major) for every key `k` of the table.
- **C `setTiles(indexes, count, width)`** does nothing unless `count` is a whole number of rows. It stores the
  indexes as given.
- **Sizes:** `getSize`, `getPixelSize` and `getTileSize` return integers. `getTileSize()` is nil without an image
  table, and 65535, 65535 for an image table without images. C `getPixelSize` returns the map's size.
- **Drawing:** tile index n draws image n of the table (not n + 1). `draw(x, y, sourceRect)` draws only that region of
  the map, its top-left placed at (x, y). `draw` and `drawIgnoringOffset` floor fractional positions. In the
  Simulator `tilemap:drawIgnoringOffset` applies the draw offset, unlike `image:drawIgnoringOffset`
  (`tests/probes/tmoffq`); what the device does is not known; check on hardware.
- **`getCollisionRects(emptyIDs)`** returns rects in tile coordinates, merged along rows, treating 0 as empty; a
  measured 2 by 2 case gives (0, 0, 2, 1) and (1, 1, 1, 1), not pixel rects.
- An unset map has no phantom tiles: a level built by scanning a layer for tile 1 must not find every untouched
  tile (`tests/probes/tmunset`).
- Skip drawing images that lie entirely outside the target: a large map otherwise costs most of a frame.
- In C, `newBitmapTable(count, w, h)` cells report a size of 65535 by 65535 until loaded, on the device (3.1.2, by
  analysis); the Simulator matches. So a tilemap built from them has 65535-pixel cells (see
  [images.md](images.md#c-bitmap-tables)).

## Implementation notes

- Remember, per sprite, where and how it was last drawn (screen rect, z-index, visibility, image change counter),
  and the area it actually drew; collect dirty rects from those at update time.
- Keep the clip-rect "set" flag separate from the rect.
- Count sprites added during the drawing pass as drawn, so they do not dirty the next frame.
- Ignore nested `sprite.update()` calls with a depth flag.
