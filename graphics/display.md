# Display, frame buffer and drawing state

This file describes the display and its frame buffer, and the drawing state that every primitive goes through: the
draw target and the context stack (`pushContext`, `popContext`, `lockFocus`), the draw offset, clip rects, the
stencil, colours and draw modes as state, the background colour and `clear`, the display settings (scale, inversion,
mosaic, flip, offset, refresh rate), the areas that direct drawing marks dirty for the sprite system, and frame
timing as drawing sees it. The rasterization of the primitives themselves is in [drawing.md](drawing.md); bitmaps,
image draw modes and fades are in [images.md](images.md), text in [text.md](text.md), and the sprite system's
redraw in [sprites.md](sprites.md). Behaviour is as measured in the Simulator (SDK 3.1.1) unless it says the device
(3.1.2, by analysis).

## The display and the frame buffer

- The display is 400 by 240 pixels, 1 bit per pixel. `display.getWidth()`, `getHeight()` and `getSize()` return
  integers (400, 240); `getSize` returning floats (400.0) is a common mistake that shows when a game prints the value.
  `display.getRect()` is a rect (0, 0, 400, 240). C `display->getWidth()` and `getHeight()` are 400 and 240.
- The frame buffer has 52-byte rows (`LCD_ROWSIZE`), so each row carries 16 bits of padding past pixel 400.
  `getDisplayBufferBitmap`, `copyFrameBufferBitmap`, `getDisplayImage` and `getWorkingImage` are all 400 by 240 and
  report 52-byte rows. A common mistake is to make the frame buffer 416 pixels wide to get 52-byte rows; that width
  then leaks into display images, clip rects and C bitmaps.
- The pixel bytes are most significant bit first, 1 for white.
- The screen starts white.
- Before the first frame is shown, the display buffer's row padding reads 0 in the Simulator.
- `playdate.display.flush()` exists and returns nothing.

### The two frames

- `gfx.getWorkingImage()` returns a copy of the frame being drawn.
- `gfx.getDisplayImage()` returns a copy of the last completed frame, so drawing done this frame shows up in it only
  on the next frame. Each call returns a new image (`tests/probes/disppl`).
- C `copyFrameBufferBitmap` returns a usable bitmap copy of the frame buffer (400 by 240, 52-byte rows).

### `display.loadImage(path)`

The image is read over the frame buffer, and its 16-byte image header must equal the frame buffer's, which has
52-byte rows. pdc stores a 400 by 240 image with 50-byte rows, so a normal full-screen image raises "loaded file
properties don't match framebuffer's", prefixed with the caller's position. The device (3.1.2, by analysis) does the
same.

## Display settings

| Function | Behaviour |
| --- | --- |
| `display.setScale(n)` / `getScale()` | `getScale` returns an integer. At scale n, `getWidth` and `getHeight` are 400 / n and 240 / n (C `getWidth` is 200 at scale 2). |
| `display.setInverted(flag)` / `getInverted()` | Inverts what is shown; see below for its effect on `getDisplayImage`. |
| `display.setMosaic(x, [y])` / `getMosaic()` | `getMosaic` returns the two values as integers. |
| `display.setFlipped(x, y)` | Accepted; flips what is shown. |
| `display.setOffset(x, y)` / `getOffset()` | Round-trips as integers. It moves what is shown, not the drawing coordinates. |
| `display.setRefreshRate(r)` / `getRefreshRate()` | See "Frame timing". The default is 30; `getRefreshRate` returns a float (30.0). |

The C functions (`setScale`, `setInverted`, `setMosaic`, `setFlipped`, `setOffset`, `setRefreshRate`) behave the same.
A common binding mistake is registering `display.setOffset` to the mosaic function.

### Display scale: the screen is the scaled area

At `display.setScale(n)` with n above 1, the screen is the top-left (400 / n) by (240 / n) of the frame buffer
(`tests/probes/scale2q`):

- drawing to the screen is clipped to that area, also after `clearClipRect`;
- `gfx.clear()` clears only that area;
- the rest of the frame buffer keeps whatever it had. It is not shown, but a game that reads the frame buffer
  (`getDisplayImage`) sees it.

### Display inversion

Changing `display.setInverted` inverts the last completed frame at once, so `getDisplayImage` returns it inverted
until the next frame completes. Setting the same value again does nothing, and the frames after that are stored
uninverted (`tests/probes/dispinv`). This is separate from an image's own inverted flag ([images.md](images.md)).

## Drawing coordinates

### The draw offset

- `setDrawOffset(x, y)` is added to every drawing call's coordinates. `getDrawOffset()` returns floats in Lua.
- The clip rect set by `setClipRect` is in drawing coordinates too (it moves with the offset); `setScreenClipRect` is
  not (see below).
- Patterns, dither patterns and stencils are anchored to the target, not to the offset.
- `image:drawIgnoringOffset` ignores it. `tilemap:drawIgnoringOffset` applies it in the Simulator (SDK 3.1.1), unlike
  the image version; this contradicts Inside Playdate; check on hardware. See [images.md](images.md).
- During sprite drawing, the offset is the sprite's position plus the global offset, unless the sprite ignores the
  draw offset; see [sprites.md](sprites.md).

### Clip rects

- `setClipRect(x, y, w, h)` is in drawing coordinates: the draw offset applies to it, in Lua and C. With an offset of
  (2, 2), `setClipRect(4, 4, 6, 6)` clips to screen pixels 6 to 11.
- `setScreenClipRect(x, y, w, h)` is in target coordinates and ignores the draw offset.
- `getClipRect()` returns the clip rect intersected with the current target (the screen, or the image of
  `pushContext`), in drawing coordinates, as integers. When nothing of the rect is inside the target it returns 0, 0,
  0, 0. With no clip set it returns the whole target (0, 0, 400, 240 for the screen). Probe: `tests/probes/drawdiff`.
- `getScreenClipRect()` returns four integers, as set (not a rect object).
- `clearClipRect()` restores drawing to the whole target, in Lua and C. A common mistake is to store "no clip" as an
  empty rect and then treat every pixel as outside it, so that nothing can be drawn after `clearClipRect` until a new
  clip rect is set. Keep a separate flag; for the screen, use the display size.
- An empty clip rect (zero size, or one that does not touch the target) draws nothing.
- At a display scale above 1, the screen's clip is also cut to the scaled area.
- Sprite clip rects (`sprite:setClipRect`, `setClipRectsInRange`) and their rounding are in [sprites.md](sprites.md).

### The stencil

- **Rule:** drawing passes only where the stencil pixel is white. Black and clear stencil pixels both block. The
  stencil is in target coordinates (the draw offset does not move it); an untiled stencil blocks everything outside
  its own bounds, and a tiled one repeats. An image's inverted flag and mask count when it is read.
- **`gfx.setStencilImage(image, [tile])`** raises "stencil images must be at least 32 pixels wide" for a narrower
  image. `sprite:setStencilImage` does not check.
- **`gfx.clearStencil()`** removes it.
- Probe: `tests/probes/stencil` (9 cases).

#### `setStencilPattern`

`gfx.setStencilPattern` and `sprite:setStencilPattern` take one of:

- a table of eight rows;
- eight row numbers;
- a level with an optional dither type, which is Bayer 4x4 when left out.

An explicit nil or a string as the type raises "arguments to setStencilPattern() should be a table or list of pixel
values or an alpha level with optional dither type".

**A level** builds an 8 by 8 stencil from the same per-cell thresholds as `drawFaded` for that dither type (the fade
tables are in [images.md](images.md)), with one difference: the level is rounded to the nearest 1/255 instead of
floored. With a = round(level * 255), a cell passes when a reaches its cell value:

| Type | Cell value |
| --- | --- |
| None | 128 everywhere |
| DiagonalLine | 49, 113, 177, 241 by (x + y) mod 4 |
| VerticalLine | the same by x mod 4 |
| HorizontalLine | the same by y mod 4 |
| Screen | 32 and 160 on even rows, 96 and 224 on odd rows (for even and odd x) |
| Bayer 2x2 | 51 205 / 153 103 (rows top down) |
| Bayer 4x4 | 15 136 45 166 / 197 75 226 106 / 61 181 31 150 / 240 121 211 91 |
| Bayer 8x8 | 4m + 1 for Bayer matrix entry m, and 2 for entry 0 |

So the first diagonal-line cell turns on at 48.5 / 255, and Bayer 4x4 at 0.5 is a checkerboard with (0, 0) drawn.
Bayer 2x2 has five distinct steps. The error-diffusion types (FloydSteinberg, Burkes, Atkinson) give the same
stencil at every level: only pixels 1 and 2 of the first row pass. Probes: `tests/probes/stpat`,
`tests/probes/stpat2` (each cell's level found by bisection).

## The context stack

### What a context holds

A context holds the target (the frame or an image), the draw offset, the clip rect, the stencil, the colour or
pattern, the line width, cap style and stroke location, the image draw mode, the font and tracking, and the
background colour.

**The C API and Lua keep separate settings** for some of these: a C `setDrawMode`, `setFont`, `setTextTracking`,
`setLineCapStyle` or `setBackgroundColor` does not change Lua's image draw mode, font, tracking, line caps or the
colour Lua's `clear()` uses, and the other way round. Each side's `pushContext` and `popContext` saves and restores
only its own settings. The draw offset, clip rect, stencil and target are shared. Probes: `tests/probes/modeq`,
`tests/probes/ctxq`. (The SDK's Particles example draws its Lua text in Lua's Copy mode although its C code set
Inverted.)

### `pushContext` and `popContext`

- **`pushContext(image)`** makes the image the target. It keeps the line width, colour, font tracking and image draw
  mode; it starts with a draw offset of (0, 0) and a clip rect covering the whole image.
- **Changes inside do not leak out:** after `popContext`, the line width, draw offset and the rest are as they were
  before `pushContext`.
- **Lua `pushContext()` with no image** keeps the current target.
- **C `pushContext(NULL)`** means the display frame buffer, with the screen's own clip rect and draw offset; drawing
  settings such as the colour carry over. This differs from Lua's form without an image. (rubido pushes an image,
  then the screen, then draws the image; if NULL keeps the current target, the draw goes into the image itself.)
- **`popContext()`** with nothing pushed raises "no pushed context!". It refuses to pop a focus context (below).

### `lockFocus` and `unlockFocus`

- **`lockFocus(image)`** is a `pushContext(image)` marked as a focus context. Any focus contexts on top are popped
  first, so calling `lockFocus` twice does not nest. Inside it the draw offset is 0 and the clip rect is the image.
  nil is allowed; anything else that is not an image is a type error.
- **`unlockFocus()`** pops the top context only when it is a focus context, and restores every setting changed since.
- A `pushContext(other)` inside `lockFocus` draws into `other`; after its `popContext`, drawing returns to the locked
  image.
- CoreLibs' `gfx.imageWithText` uses `lockFocus`.

Probe: `tests/probes/ctxq`.

## Colours, line state and draw modes

- `setColor(c)`: `kColorBlack` 0, `kColorWhite` 1, `kColorClear` 2, `kColorXOR` 3. Primitives are drawn in the colour
  or the current pattern ([drawing.md](drawing.md)).
- `setLineWidth(w)` and `getLineWidth()` (a float in Lua).
- `setLineCapStyle(style)`: `kLineCapStyleButt` 0, `kLineCapStyleSquare` 1, `kLineCapStyleRound` 2.
- `setStrokeLocation(loc)` (Lua): `kStrokeCentered` 0, `kStrokeInside` 1, `kStrokeOutside` 2. The C header numbers
  inside and outside the other way round. `getStrokeLocation` returns an integer.
- `setPolygonFillRule(rule)`: `kPolygonFillNonZero` or `kPolygonFillEvenOdd`.
- **Image draw mode** (`setImageDrawMode` in Lua, `setDrawMode` in C): `kDrawModeCopy` 0, `WhiteTransparent` 1,
  `BlackTransparent` 2, `FillWhite` 3, `FillBlack` 4, `XOR` 5, `NXOR` 6, `Inverted` 7. It applies to images and text;
  see [images.md](images.md). C `setDrawMode` returns the previous mode. A sprite's own draw mode applies only to its
  image or tilemap; its draw callback runs with the current global mode ([sprites.md](sprites.md)).

## The background colour and `clear`

- `setBackgroundColor(c)` sets the colour that `clear()` uses by default and that the sprite system fills dirty areas
  with. `getBackgroundColor()` returns a float in Lua. C and Lua keep separate background colours.
- **`gfx.clear([color])` clears the current target**, such as the image of `pushContext`, in Lua and C. On the device
  (3.1.2, by analysis) it fills only the clip rect (the whole target when the clip covers it); at a display scale it
  clears only the scaled area (measured in the Simulator).
- With no sprites, `sprite.update()` draws nothing, even after `setBackgroundColor`.

### Image targets and `clear`

On the device (3.1.2, by analysis), clearing an image fills whole rows, row padding included, and clearing with black or
white makes an existing mask fully opaque. See [images.md](images.md) for row sizes.

## Dirty areas from direct drawing

The sprite system redraws only dirty areas ([sprites.md](sprites.md)). Once any sprite has been created, each drawing
call made straight to the screen (not into an image, and not by the sprite system itself) adds its bounds as a dirty
area. The next `sprite.update()` fills that area with the background colour and redraws the sprites over it, so text or
shapes a game stops drawing disappear.

- **Before the first sprite nothing is tracked.** A game that has never called `gfx.sprite.new` (or C `newSprite`)
  can call `sprite.update()` without anything being erased. Creating one sprite, even one never added, starts the
  tracking for good; removing every sprite does not stop it.
- **Each call gives its own rect.** Two separate calls give two separate areas. Drawing entirely off screen, or into
  an image, gives none.
- **During sprite drawing** (inside a draw callback or the background callback) drawing dirties nothing.
- **The bounds are the shape's, not its pixels'.** Each rect is clipped to the clip rect and the target, after the
  draw offset:

| Call | Dirty rect |
| --- | --- |
| 1-pixel line | the end points' bounding box, inclusive (a line from (-10, -5) to (190, 145) dirties rows 0 and 1, though its first pixel is on row 3) |
| Wide line | the box of the quad's corners, inclusive, united with the round caps' rects; a zero-length wide line only its caps |
| Pixel | 1 by 1 |
| `fillRect` | the rect: `fillRect(50, 60, 30, 20)` gives 50, 60, 30, 20 |
| 1-pixel `drawRect` | the rect |
| Wider `drawRect` (any location) | the stroke's outer box plus one pixel right and down |
| `drawRoundRect` | the rect only, even when a centred or outside stroke extends past it |
| Ellipse outline, arc | the rect |
| Filled ellipse (and outlines wide enough to be drawn filled) | x to x + 2 (w >> 1) + 1, and the same in y: one pixel wider and taller than the rect for even sizes |
| Polygons, triangles | the vertices' bounding box, inclusive |
| `gfx.clear()` | the clip rect (the whole screen when nothing is clipped) |
| Images | the rect of the stored pixels (as pdc trimmed them), mirrored by flips and scaled by `drawScaled`; see [images.md](images.md) |
| Text | per glyph, its stored pixels' left, right and top, extended down to the bottom of its line; see [text.md](text.md) |

For example, a line from (20, 30) to (120, 90) gives 20, 30, 101, 61. Probe: `tests/probes/dirtyb` (41 cases). An
implementation can collect the bounds with a depth counter around each public drawing function and add one rect when
the outermost call returns. A game that draws every frame but never updates sprites would grow the list without
limit, so collapsing a long list into its bounding rect is a reasonable implementation choice (not measured).

Whether the device tracks direct drawing the same way (including the text rule) is not known; check on hardware.

## Frame timing as drawing sees it

- **Refresh rate.** `display.setRefreshRate(r)` limits the rate to 50: 60 and 1e9 read back as 50. A negative rate sets
  the default 30. Zero (as fast as possible), fractions and NaN are kept; an implementation should run as fast as
  possible for NaN, as for 0, rather than compute a frame time from it (`tests/probes/rrq`).
- **Pacing.** A game at refresh rate r gets an update every 1 / r seconds. Frames should start on a fixed schedule; a
  common mistake is to wait a whole truncated period (33 ms at 30 fps) after each frame starts, which runs games at
  about 29.4 fps. Restart the schedule after a frame that ran a whole period late.
- **What is shown.** The frame drawn during an update is shown after it. `getDisplayImage` returns the previous
  completed frame (see "The two frames"). How changes to a sprite's image made during `sprite.update()` show up is in
  [sprites.md](sprites.md).
- **The game clock** counts all running time, including time between updates; see
  [../system/time.md](../system/time.md).

### `getFPS` and `drawFPS`

- `playdate.getFPS()` is 1,000 divided by the mean of the last 30 frame durations in whole milliseconds, rounded, and
  at most 99, on the device (3.1.2, by analysis).
- On the device (3.1.2, by analysis), `playdate.drawFPS(x, y)` fills a white 15 by 12 box at (x, y) in screen
  coordinates, then draws two digits in black at (x + 1, y + 1). The digits use a built-in 6 by 10 font with a
  7-pixel advance, not the current font, and a space stands in for the tens digit below 10.
  In the Simulator (SDK 3.1.1) the glyphs and the box are the same (measured pixel for pixel), but the digits are
  spaced by width: a blank tens digit advances 4 pixels and a 1 advances 5, so single-digit rates draw their digit at
  x + 5 and 10 to 19 draw the ones digit at x + 6 (from 20 up the layout matches). The Simulator also clips the box
  to the clip rect and the screen clip rect, which the analysis of the device does not show. Check on hardware.

## Simulator and device differences

| Item | Simulator (SDK 3.1.1) | Device (3.1.2, by analysis) |
| --- | --- | --- |
| `tilemap:drawIgnoringOffset` | applies the draw offset | not known; check on hardware |
| `fillPolygon` on an open polygon object | never returns | raises "Can't fill an open polygon!" |
| `setDitherPattern` alpha for black | 0 draws solid, 1 nothing (contrary to the documentation) | not known; check on hardware |
| Display buffer padding before the first frame | reads 0 | not known; check on hardware |
| Dirty areas from direct drawing | as above | not known; check on hardware |
| `playdate.getDebugBitmap`, `playdate.debugDraw` | present | absent |
