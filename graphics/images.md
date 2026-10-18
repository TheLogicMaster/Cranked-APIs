# Images

This file covers bitmaps (Lua `playdate.graphics.image`, C `LCDBitmap`): how they are created and loaded, their
memory layout and masks, drawing them with draw modes, flips, source rects and tiling, scaling, rotation, transformed
and sampled drawing, blur, fades and blends, `vcrPauseFilterImage`, inverted images, image tables (Lua and C) and video
playback. Shapes, patterns, stencils, the drawing context, clip rects and the draw offset are in
[drawing.md](drawing.md); the frame buffer, `getDisplayImage` and the display itself are in [display.md](display.md);
text in [text.md](text.md); sprites (which draw images) in [sprites.md](sprites.md). Rules marked "on the device
(3.1.2, by analysis)" are the device's behaviour; "in the Simulator (SDK 3.1.1)" marks Simulator behaviour, and where
the two differ both are given.

Conventions: x grows right and y down; pixel (x, y) covers [x, x + 1) by [y, y + 1). `trunc` rounds toward zero,
`floor` down. "Float" means a 32-bit float; Lua numbers on the device are 32-bit integers and 32-bit floats.
`fix(v)` is trunc(v * 65536), a 16.16 fixed-point value, and `>> 16` an arithmetic shift.

## Creating images

- **`gfx.image.new(width, height, [bgcolor])`:** fractional sizes are truncated (1.99 makes 1, 10.51 makes 10). A size
  that comes out 0 is an error with the caller's line: `main.lua:6: invalid bitmap size: 0 x 20` (no line when called
  straight from `pcall`). The colour must be 0, 1 or 2 (`kColorBlack`, `kColorWhite`, `kColorClear`), otherwise
  "background color must be kColorClear, kColorBlack, or kColorWhite". `tests/probes/imgfrac`
- **A new image filled with `kColorClear`** has a mask; one filled black or white has none (`hasMask()` false,
  `getMaskImage()` nil).
- **C `newBitmap(w, h, color)`** behaves the same; `getBitmapPixel` outside the bitmap returns `kColorClear`.
- **`image:copy()`** copies the pixels, the mask and the inverted flag. C `copyBitmap` gives an independent bitmap.
- **`image:clear(color)`** (C `clearBitmap`) fills whole rows, row padding included. Clearing to black or white makes an
  existing mask fully opaque. Creating an image fills only its width, so the padding of a new image reads 0.

### Memory layout and row size

The row size (stride) depends on how the bitmap was made, and C code that reads `getBitmapData` sees it:

| Bitmap | Row bytes | Example |
| --- | --- | --- |
| C `newBitmap` | `((width + 31) >> 3) & ~3` (whole 32-bit words) | 10 px: 4; 37 px: 8; 100 px: 16 |
| Lua `image.new`, and every derived image (rotated, scaled, faded, blurred, copies) | `(width + 7) >> 3` | 4 px: 1; 100 px: 13 |
| Loaded image | the file's row size (pdc stores `(width + 7) >> 3`) | 400 px: 50 |
| Frame buffer, display buffer, menu image | 52 (`LCD_ROWSIZE`) | 400 px |
| Font glyph | `(width + 7) >> 3` | 20 px: 3 |
| Rotated copy of a 37-pixel C bitmap | `(width + 7) >> 3` of the result | 5, or 10 at twice the width |

- A mask has its image's row size (`addMask` included). Pixel bits are 1 for white and 0 for black, most significant
  bit first; mask bits are 1 for opaque.
- `getBitmapData(bitmap, &w, &h, &rowbytes, &mask, &data)` on `newBitmap(10, 3, kColorBlack)` gives 10, 3, 4, a NULL
  mask and data bytes of 0. On the display buffer it gives 400, 240, 52.
- Games do depend on this: the SDK's Exposure example counts bits with 16-byte rows over a 100-pixel Lua image whose
  rows are 13 bytes, so its counts include the next row's first 3 bytes. `tests/probes/cbench` (mode 6)
- In the Simulator the display buffer's row padding reads 0 before the first frame is shown.

## Masks and transparency

- **Opaque source images have no mask.** An image compiled from a PNG without transparency loads without a mask:
  `hasMask()` is false and `getMaskImage()` nil. This matters for derived images: a maskless image rotated by a
  multiple of 90 degrees, or scaled, stays maskless, and its uncovered pixels are black, not transparent.
  `tests/probes/rot0m`
- **`image:addMask([opaque])`:** opaque by default; `addMask(false)` makes a fully transparent mask.
- **`image:clearMask([opaque])`:** the argument must be a number (a boolean raises "bad argument #1 to 'clearMask'
  (number expected, got boolean)"). No argument or 0 makes the mask transparent; on the device (3.1.2, by analysis)
  only 1 means opaque. An image without a mask is left alone.
- **`image:removeMask()`** drops the mask; transparent pixels then read as their stored colour (black for a new clear
  image).
- **`image:getMaskImage()`** returns a new userdata on every call, but it shares pixels with the mask in both
  directions, as does a mask set with `setMaskImage`. `setMaskImage(nil)` is an argument error. C `setBitmapMask`
  returns 1. `tests/probes/shareq`, `tests/probes/identq`
- **`image:sample(x, y)`** returns the colour, with coordinates rounded as elsewhere. It returns nil when x or y is
  negative or beyond the far edge, but `kColorClear` exactly on the far edge (x equal to the width, or y to the
  height).

## The inverted flag

`image:setInverted(true)` changes how the image samples and draws, not its bytes. `tests/probes/invq`

- `copy()` keeps the flag.
- `invertedImage()` is a copy with the flag toggled, so the inverted image of an inverted image looks like the
  original. Its bytes, as C `getBitmapData` sees them, are the source's.
- Scaled, rotated, blurred, faded and transformed images of an inverted image show the inverted look.
- Example: an 8 by 6 source whose columns are `00001100` per row, inverted and drawn onto white, gives `11110011`.

## Image identity

Images are full userdata (`type` is "userdata", custom fields raise errors). Which calls give the same Lua value:

- **Same value each call:** `sprite:getImage()` (and the image given to it), `imagetable:getImage(n)` and `table[n]`.
- **A new value each call:** `getDisplayImage`, `getWorkingImage` (copies), `image:getMaskImage()`. An image put into a
  table with `imagetable:setImage` is not the value a later `getImage` returns, but they share pixels.
- **C `pushBitmap`:** each push makes a new userdata, so two pushes of one bitmap are neither `rawequal` nor `==`.

## Loading images

- **Compiled files:** `gfx.image.new(path)` loads a compiled `.pdi`, with or without the extension. pdc trims fully
  transparent edge rows and columns from the source PNG and stores the rect it kept (the left edge rounded down to a
  multiple of 8). Several behaviours below depend on these stored ("trimmed") pixels; images made at runtime have no
  trim. A file starts with a 16-byte header: the magic and a flags word (compression among them).
- **Images imported into the PDZ:** `import 'track.png'` makes pdc compile the image into `main.pdz` as an entry named
  `track` of the image type, holding the file's contents after the 16-byte header. `gfx.image.new('track')` finds it,
  and the other loaders find their types the same way (tables, fonts, strings, audio, video).
- **Letter case:** on the device (3.1.2, by analysis) names are matched ignoring letter case (its data disk is FAT), so
  `images/missile/explosion` finds `Explosion.pdt` there, as on the macOS and Windows Simulators. The Linux Simulator is
  case-sensitive. An implementation should try the exact name first, then a case-insensitive match.
- **Missing file:** `gfx.image.new(path)` returns nil and "file <path> not found: No such file".
  `gfx.imageSizeAtPath(path)` returns nil and nil for a missing file, and floats for a found one.
- **`image:load(path)`** loads into an existing image, taking the file's size, and returns true.
- **C `loadBitmap(path, &err)`** and the other loaders accept a NULL error pointer.
- **`playdate.display.loadImage`** and **`datastore.writeImage` / `readImage`**: see [display.md](display.md) and
  [../data/files.md](../data/files.md).

## Drawing images

### Positions: floored or rounded

Lua drawing calls round integer arguments to nearest with halves away from zero, but several image calls floor the
position instead (measured on ten positions from -0.7 to 177.3, `tests/probes/fracq`):

| Floor (10.7 is 10, -0.5 is -1) | Round to nearest (halves away from zero) |
| --- | --- |
| `image:draw`, `drawIgnoringOffset`, `drawTiled`, `drawSampled`, `drawCentered`, `drawAnchored`, `drawRotated`, `tilemap:draw`, `tilemap:drawIgnoringOffset` | `drawScaled`, `imagetable:drawImage`, text, sprites, shapes |

A common mistake is to apply the general Lua integer conversion to all of them; `drawIgnoringOffset` at eased
positions then sits a pixel off.

### `image:draw(x, y, [flip], [sourceRect])`

- **Arguments:** x and y as numbers or a `playdate.geometry.point`; anything else raises
  "playdate.graphics.image:draw() takes either x, y, arguments or a playdate.geometry.point object".
- **Source rect:** only that region is drawn, its top-left at (x, y). Its fields (a rect object or four numbers) are
  floored: x 2.7 is 2, -0.5 is -1, a width of 5.5 is 5. A source rect starting outside the image keeps its offset:
  from x = -1 the image is drawn one pixel to the right and the part outside the image is left empty (not clamped).
  `tests/probes/srcrect`
- **Flips:** `kImageUnflipped`, `kImageFlippedX`, `kImageFlippedY`, `kImageFlippedXY` mirror the whole image.
- **`drawIgnoringOffset(x, y)`** draws at (x, y) in target coordinates whatever the draw offset. (In the Simulator,
  `tilemap:drawIgnoringOffset` applies the offset, unlike the image version; check on hardware.)
- **`drawCentered` and `drawAnchored`** go through `draw`, so they floor too.
- **Images entirely outside the target** draw nothing; an implementation can return early once the destination rect,
  after the draw offset, misses the target. Drawing only the part inside the clip rect is equivalent.

### Draw modes

The image draw mode (`gfx.setImageDrawMode`, C `setDrawMode`) applies to images, glyphs and tilemaps. Lua and C keep
separate draw modes: a C `setDrawMode` does not change what Lua's `getImageDrawMode` returns or what Lua drawing uses,
and the other way round (`tests/probes/modeq`). Each mode, for an opaque source pixel (transparent pixels never draw):

| Mode | Result |
| --- | --- |
| `kDrawModeCopy` | the source pixel |
| `kDrawModeWhiteTransparent` | black source pixels only |
| `kDrawModeBlackTransparent` | white source pixels only |
| `kDrawModeFillWhite` | white |
| `kDrawModeFillBlack` | black |
| `kDrawModeXOR` | destination XOR source (white source pixels invert the destination) |
| `kDrawModeNXOR` | destination XOR NOT source (black source pixels invert the destination) |
| `kDrawModeInverted` | the inverted source pixel |

The inverted flag changes the source pixels that the mode sees. A sprite's own image draw mode applies to its image
only; see [sprites.md](sprites.md).

### `drawTiled(x, y, width, height, [flip])`

- Tiles the image from (x, y) and stops exactly at the given width and height.
- With a flip, each whole tile is flipped; a tile cut by the right or bottom edge is the whole flipped tile clipped
  to the rect, so it shows the part of the flipped tile nearest its own top-left corner. `tests/probes/ddrep`

## Scaling

`image:drawScaled(x, y, scale, [yscale])`, `image:scaledImage(scale, [yscale])` and C `drawScaledBitmap` /
`scaledBitmap`. Exact on every probe (`tests/probes/sc2`, `sclclip`, `negclip`).

- **Size:** trunc(|width * xScale|) by trunc(|height * yScale|).
- **Zero scale** draws nothing.
- **Negative scales (Lua):** mirror that axis: -1 turns the image 180 degrees, and (2, -1) flips it vertically.
  `drawScaled` puts the mirrored image's top-left corner at (x, y). C `drawScaledBitmap` draws nothing for a negative
  scale (measured in the Simulator).
- **Sampling:** rows sample at their top edge and columns near their centers, both through 16.16 fixed point; a
  negative scale counts rows from the bottom and columns from the right.
- **Trimmed images:** only the stored pixels are drawn, and their rect is scaled on its own. So a trimmed image drawn
  partly above the target can start a row lower than the untrimmed sampling gives, and its run can end a row past the
  untrimmed image's scaled height.

In device coordinates (the position with the draw offset added; X and Y already rounded by Lua):

```
left = trunc(X + leftTrim * sx)            (sx > 0)    or trunc(X + rightTrim * -sx)   (sx < 0)
top  = trunc(Y + topTrim * sy)             (sy > 0)    or trunc(Y + bottomTrim * -sy)  (sy < 0)
W = trunc(|storedWidth * sx|); H = trunc(|storedHeight * sy|)
row R of the run (top <= R < top + H):
    stored row = fix((R - top) / sy) >> 16                  (sy > 0)
                 fix(-(top + H - 1 - R) / sy) >> 16         (sy < 0)
columns: step = trunc(65536 / sx)
    acc = step / 2, plus storedWidth * 65536 when sx < 0
    each column takes stored column acc >> 16, then acc += step
only the part inside the clip rect is visited
```

`scaledImage` makes a trunc(|width * sx|) by trunc(|height * sy|) image (the untrimmed size) and draws into it at
(0, 0) the same way. For a maskless source the result is maskless and starts black, so pixels the draw does not reach
stay black: at scale 0.75 the last column and row of a 0-degree `rotatedImage(0, 0.75)` are black.

## Rotation

`image:rotatedImage(angle, [scale, [yscale]])`, `image:drawRotated(x, y, angle, [scale, [yscale]])`, C
`rotatedBitmap(bitmap, degrees, xscale, yscale, &allocedSize)` and `drawRotatedBitmap(bitmap, x, y, degrees,
centerx, centery, xscale, yscale)`. Rotation is clockwise. `tests/probes/rot3` (180 random cases: 179 exact; the
miss is a single pixel at a fractional position), `tests/probes/rotctr`, `rotxy`, `rot0frac`, `rotsz`.

### Angle and path

- **Reduction:** whole turns are dropped from angles of 360 and up; negative angles add whole turns plus one, so -15
  becomes 345 and -360 becomes 360, not 0.
- **Right angles at unit scale:** at 0, 90, 180 or 270 degrees with a scale of exactly 1 or -1 the image is blitted
  (copied, rotated or flipped). `drawRotated` then puts the rotated image's corner at (x - w / 2, y - h / 2), rounded
  to nearest with **halves toward zero**, in target coordinates after the draw offset. Examples: a 247-pixel-wide
  image at y = 120 has its corner row at -3.5, which is -3; with a draw offset of 20, a 21-pixel-wide image at
  x = -3 has its corner at -3 + 20 - 10.5 = 6.5 in the target, so 6 (-14 in drawing coordinates).
- **0 or 180 degrees with another scale:** a scaled draw (see Scaling), mirrored on both axes at 180, its corner at
  the center minus half the scaled size, truncated.
- **Every other case** goes through the sampler below.
- **Position:** Lua `drawRotated` floors a fractional x and y first (-2.5 is -3).
- **C `rotatedBitmap`** with an angle of exactly 0 is the scaled image.
- **Huge scales** (1e30) produce nothing; an emulator should bound the work to the target.

### Size

The output size is the bounding box of the image's four corners rotated about its top-left corner, with the scaled
width and height kept signed, in single precision, with a small tolerance:

```
w = width * sx; h = height * sy                 (signed)
corners (0, 0), (w, 0), (0, h), (w, h) rotated clockwise by the angle about (0, 0)
W = ceil(max x - 0.001) - floor(min x + 0.001); H likewise
```

Examples: 8 by 6 at 90 degrees is 6 by 8; 12 by 6 at 30 degrees is 14 by 12; 6 by 14 at -20 degrees is 11 by 17 (a
pixel more than the rounded-up rotated extent, and lopsided). A common mistake is to compute this in double precision
with a larger tolerance, which comes out a pixel short at 45 and 135 degrees.

### Sampler

Each output row's start is mapped back through the inverse rotation and scale in single precision, converted once to
16.16 fixed point, and stepped per pixel:

```
th = -(angle * pi) / 180            (float);  s = sin th;  c = cos th
step per column: du = fix(c / sx); dv = fix(s / sy)
for each output row y:
    r = (y - Y) + 0.5;  f = (left + 0.5) - X
    u = fix(r * (-s / sx) + f * (c / sx) + 0.5 * sourceWidth)
    v = fix(r * (c / sy)  + f * (s / sy) + 0.5 * sourceHeight)
    for each output column: take source (u >> 16, v >> 16) if inside the image, else transparent
                            u += du;  v += dv
```

- **Destination center (X, Y):** for `rotatedImage`, the integer half of the output size; for `drawRotated`, the
  floored position. On each axis whose source size (width for X, height for Y) is odd it moves up or left by half a
  pixel.
- **Uncovered pixels** are transparent, except that a maskless source at a right angle gives a maskless, black-edged
  result (see Masks).
- **Another center (C `drawRotatedBitmap`):** the destination rect bounds the four corners rotated about the center
  point, in single precision with fused multiply-adds, from floor(min + 0.001) to ceil(max - 0.001) on each axis. It is
  filled by the `drawSampled` sampler (below) with the center point given as its fraction of that rect, the source
  point at (centerx, centery) of the image, and the matrix (cos / sx, -sin / sy, sin / sx, cos / sy). This path is used
  for every angle except 0 and 180, and for 90 and 270 only with a scale.

**Simulator versus device:** the Simulator appears to compute each rotated pixel's source position on its own in
single precision, while the device (3.1.2, by analysis) steps 16.16 fixed point along each row as above. The difference
is single pixels: at 190.4 degrees and scale 2.3, a pixel 44 columns into a row samples u = 1.9997 per pixel but 2.0004
after stepping (`tests/probes/ddrep`). Check on hardware.

Rotated sprites use `rotatedImage`; their placement is in [sprites.md](sprites.md).

## `transformedImage` and `drawWithTransform`

Both take a `playdate.geometry.affineTransform`. Exact on `tests/probes/trsz` (18 cases), `xf` (12) and `dwt` (10).

- **`image:transformedImage(xform)`:** the image's corners, centered on the image (+-width / 2, +-height / 2), are
  transformed by the linear part (no translation) in single precision. The size is ceil(max) - floor(min) on each
  axis. Single precision matters: the float error of cos 90 degrees (about -4.4e-8) pushes a corner just past an
  integer, so a 10 by 6 image rotated 90 degrees comes out 8 by 10, and at 180 degrees 12 by 8. Pixel (x, y) samples
  the inverse transform at (x - W / 2 + 0.5, y - H / 2 + 0.5) from the result's integer center, plus a further half
  pixel on each axis whose source size is odd. Each row's start is converted once to 16.16 fixed point, then stepped.
- **`image:drawWithTransform(xform, x, y)`:** x and y are numbers. The image's corners are transformed about its
  center including the translation, in single precision with fused multiply-adds; the destination rect runs from
  floor(min + x) to ceil(max + x), and likewise in y. So the image is centered on (x, y) and the translation moves it:
  `t:scale(2); t:translate(4, 4)` draws the doubled image 4 pixels right of and below (x, y). The rect is filled by
  the `drawSampled` sampler with center and offset 0.5, the inverse of the linear part as (dxx, dyx, dxy, dyy) =
  (m22, -m21, -m12, m11) / det, no tilt, z = 1 and no tiling.
- **Old games:** on the device (3.1.2, by analysis) there is also a compatibility path for games built with SDKs before
  1.5.0, which is not described here.

## `drawSampled`

`image:drawSampled(x, y, width, height, centerx, centery, dxx, dyx, dxy, dyy, dx, dy, z, tiltAngle, tile)` fills the
width by height rect at (x, y) by sampling the image through a matrix with a perspective tilt. It is the same sampler
as rotation. Exact on 100 random cases (centers, matrices with cross terms, offsets, z from 4 to 64, tilts from -60
to 80 degrees, with and without tiling; `tests/probes/ds2`).

```
t = (tiltAngle * pi) / 180                         (float)
hx = 0.5, or 1.0 when the image width is odd;  hy = 0.5, or 1.0 when the image height is odd
for each destination row j (0 .. height - 1):
    r = j - centery * height                       (rows below the center row)
    d = z cos t + r sin t                          (one fused multiply-add)
    if d == 0: skip the row
    q = r z / d + hy
    k = 1 - q sin t / z                            (this row's x scale)
    f = hx - centerx * width * k                   (fused)
    u = fix(dx * imageWidth + (f dxx + q dxy))     (each sum fused, rounded once)
    v = fix(dy * imageHeight + (f dyx + q dyy))
    du = fix(k dxx); dv = fix(k dyx)
    for each destination column: sample (u >> 16, v >> 16); u += du; v += dv
```

- **Matrix layout:** per destination column the source moves by (dxx, dyx); per destination row by (dxy, dyy). The
  documented formula (x' = dxx x + dyx y + dx) assigns the cross terms the other way; follow the measured layout.
- **dx and dy are fractions of the image size;** the center values move the transform's origin within the
  destination rect. With an identity matrix one source pixel maps to one destination pixel.
- **Tiling** wraps each coordinate: s mod size for s >= 0, size - ((-s) mod size) for s < 0. So a negative coordinate
  that is an exact multiple of the size wraps to the size itself, which is outside the image, and that pixel is left
  empty.
- **Without tiling** pixels outside the image are skipped.
- **Clipping:** an implementation may visit only the rows and columns inside the clip rect, provided each row's
  fixed-point start is advanced to the first visible column in wrapping 32-bit arithmetic, so the samples are those of
  the full loop.
- **Simulator versus device:** the x86 Simulator rounds the products and sums separately, so on tilted draws a few
  rows a frame differ where a source row boundary falls (the SDK example drawSampled2: rows about 33 apart). On the
  device (3.1.2, by analysis) the fused operations above are used; check on hardware.

## Blur

`image:blurredImage(radius, numPasses, ditherType, [padEdges, [xPhase, yPhase]])` and `image:drawBlurred(x, y, radius,
numPasses, ditherType, ...)`. Exact on `tests/probes/blurq` and `blurq2`; 113 of 120 randomized cases in
`tests/probes/blurq3` (masks, trimmed images, radii 0 to 6, 1 to 3 passes, every dither type, phases, padding, clips,
offsets and flips), 58 of 60 near the edges in `blurq4`.

- **Bytes:** each pixel becomes a byte, white 255 and black 0 (0xBF and 0x40 for the three error diffusion types).
- **Edge value:** everything outside the image's stored pixels counts as the byte of the colour of the top-left stored
  pixel. So a white-cornered image behaves as if surrounded by white, and one with a black corner as if surrounded by
  black. (A model that always counts the outside as white is right only for the first kind.)
- **Masks:** a mask becomes a second plane, opaque as the white byte and transparent or outside as the black byte. It
  is blurred the same way, with the image's edge value, and dithered like the image.
- **Work area:** the result's bounds cut to the stored pixels, then grown by the radius on every side. For
  `blurredImage` the bounds are the image, grown by the radius on every side with `padEdges` (a 12 by 12 image at radius
  2 becomes 16 by 16). For `drawBlurred` they are the destination grown by the radius and cut to the clip rect.
- **Each pass** is a horizontal and then a vertical running box sum over 2r + 1 bytes, each sum divided by 2r + 1 with
  truncation, positions outside counting as the edge value.
- **Dithering the result:**
  - Ordered types keep a pixel white where its byte exceeds the type's threshold for that cell; the thresholds are
    those of the fades (next section).
  - `kDitherTypeNone` keeps bytes at or above the x phase, or 128 when the x phase is 0.
  - Floyd-Steinberg, Burkes and Atkinson diffuse their error in wrapping byte arithmetic.
  - The pattern sits at the result's stored corner plus the phase; for `drawBlurred`, at the destination's clipped
    corner plus the draw offset and the phase.
- **Arguments:**
  - A radius below 1 returns the image itself (`blurredImage`) or draws it plainly (`drawBlurred`).
  - `blurredImage` reads the phases only when both are given.
  - `drawBlurred`, counting the image as argument 1: a seventh argument alone is the flip; with eight or nine
    arguments the seventh and eighth are the phases and the ninth is the flip.
- **Undefined case:** the line dither types with a negative phase give undefined results. In the Simulator they
  behave like thresholds near 0; on the device they are unknown (check on hardware).
- **Open:** `drawBlurred` where the clip leaves only the blur margin beyond the image, and one flipped, clipped
  `drawBlurred` with Floyd-Steinberg.

## Fades and blends

### Fades

`image:fadedImage(alpha, ditherType)` and `image:drawFaded(x, y, alpha, ditherType, [flip])` keep each pixel's colour
and make pixels transparent: a fade is the blur above with radius 0, applied to the mask plane, which is built from
alpha. A pixel stays opaque only where it was opaque and the dither keeps it. `tests/probes/fadetab` (all 257
levels), `fadenone`, `fadediff`, `fadeargs`, `fadetype`, `fadetype2`, `fadeph`, `fadeneg`.

With a = floor(clamp(alpha, 0, 1) * 255), an ordered type keeps a pixel when a reaches its cell's value (measured
black-box, by bisecting each cell's switching alpha):

| Type | Cell value |
| --- | --- |
| Bayer 8x8 | 4m + 1 for the Bayer matrix entry m at (x mod 8, y mod 8); entry 0 needs 2 |
| Bayer 4x4 | by position, rows top down: 15 136 45 166 / 197 75 226 106 / 61 181 31 150 / 240 121 211 91 |
| Bayer 2x2 | 51 205 / 153 103 |
| Diagonal line | 49, 113, 177, 241 by (x + y) mod 4 |
| Vertical line | the same by x mod 4 |
| Horizontal line | the same by y mod 4 |
| Screen | 32 and 160 on even rows, 96 and 224 on odd rows (even and odd x) |

These are not the `setDitherPattern` tables. The approximation "kept where (m + 0.5) / n^2 < alpha" is close for
the Bayer types but not exact.

- **`kDitherTypeNone`:** the threshold is the pattern's x phase when that is nonzero, and 128 otherwise. `fadedImage`
  has phase 0, so it keeps every opaque pixel from alpha 0.51 (a = 130) and none at 0.501. `drawFaded`'s x phase is
  the target x of the drawn part: at x = 3 any alpha from 3/255 draws the whole image; at x = 0 it switches at 128.
- **Error diffusion types:** real error diffusion of the alpha plane, scaled to 0x40 to 0xBF.
- **Anchoring:** the pattern's cell (0, 0) lands on the first stored pixel, that is the destination position (with
  the draw offset) plus pdc's trimmed margin; `fadedImage` is anchored to the stored pixels the same way. `drawFaded`
  fades only the part inside the clip rect: when the image's top is above the target's top (or the clip), the
  pattern's rows start again at the first stored row actually drawn; columns keep the anchored phase.
- **Arguments:**
  - Alpha and the type are required. A missing or nil value raises "bad argument #3" (alpha) or "#4" (type) for
    `drawFaded`, "#1" or "#2" for `fadedImage`. A non-integer type raises "number has no integer representation".
  - A type outside 0 to 10 acts like `kDitherTypeNone` at phase 0 (threshold 128); at any other phase it keeps nothing.
  - `drawFaded` takes an optional flip as its sixth argument.
  - An alpha of 1 or more draws plainly. `fadedImage` treats a negative alpha as 0. In the Simulator an alpha above 1
    keeps every opaque pixel; on the device (3.1.2, by analysis) it may wrap (check on hardware).

### Blends

`image:blendWithImage(other, alpha, ditherType)` returns a new image mixing the two by an ordered dither:

- **Weight:** alpha is this image's weight, as documented. With a = floor((1 - alpha) * 255), each pixel comes from
  `other` (with its transparency) where a reaches the cell's value in the table above, and from this image elsewhere.
- **Anchoring:** at the image origin, not the stored pixels.
- **Transparency:** each pixel's transparency comes from the image that supplies it.
- **Simulator detail:** on a trimmed image, the Simulator leaves 4 pixels of the last stored column transparent
  although both inputs are opaque there. Not modeled.
- `blendWithImage(nil, ...)` is an argument error.

### `setDitherPattern` and image-derived levels

`gfx.setDitherPattern(alpha, [ditherType])` sets the drawing colour to a dither of the current colour; the full rules
are with patterns in [drawing.md](drawing.md). In short (measured in the Simulator):

- Alpha acts as transparency for black as well as white: 0 draws solid colour, 1 draws nothing. The documentation
  says this inversion applies to white only; check on hardware.
- A cell is drawn when alpha * 255 is at most its table value + 0.5, so exactly halfway draws. Each ordered type has
  its own nested 8 by 8 table, different from the fade tables above. Without a type, the type is Bayer 8x8.
- The error diffusion types draw nothing for an 8 by 8 fill but draw in larger fills; not modeled.
- `setStencilPattern(level, [type])` uses the fade thresholds above, with the level rounded to the nearest 1/255
  instead of floored; its default type is Bayer 4x4.

## `vcrPauseFilterImage`

`image:vcrPauseFilterImage()` returns a new image of the same size, a "paused tape" effect. The rules below, with
their constants, reproduce the Simulator's output exactly on 40 consecutive full-screen calls (`tests/probes/vcr2`,
3.84 million pixels; changing any constant by one breaks the match) and on `tests/probes/vcr`, except where the
offset is negative (see the last item):

- **Randomness:** a single global 16-bit LFSR, used only by this filter and never reset; its start-up state is 0xB1AD.
  So consecutive calls give different results, and the sequence depends on every earlier call since start-up.
- **Offset:** a float horizontal offset starts at a random 0 to 13 and, after each row, drifts by a random 0 to 3
  minus 1.64.
- **Rows:** the image starts black and is filled row by row. Each row draws one random value and is one of three
  kinds:
  - noise rows, more likely near the bottom (rows below 211), where 2 in 10 pixels are white;
  - bright rows (1 in 60), white except 1 pixel in 8;
  - other rows, which copy the source pixel at x plus the offset, except that 1 pixel in 177 turns white and 2 in 177
    stay black.
- **Reading past the row:** the copy reads past the end of a row into the next row as stored in memory, so the result
  depends on the image's row size (see Memory layout).
- **Mask:** copied unchanged.
- **Negative offset:** where the offset is negative, the Simulator copies bit (x + offset) & 7 of the row's first byte,
  while on the device (3.1.2, by analysis) those pixels stay black; check on hardware.

## Image tables

### Lua `playdate.graphics.imagetable`

- **`imagetable.new(path)`** loads a compiled `.pdt`. It also accepts the source file name, with or without the
  extension and the `-table-W-H` suffix: "images/tiles-table-8-8.png", "images/tiles-table-8-8" and "images/tiles.png"
  all load "images/tiles.pdt". A missing file returns nil and "file <path> not found: No such file".
- **`imagetable.new(count, [cellsWide], [cellSize])`** makes an empty table of `count` slots. A count that is not a
  whole number (4.4) makes an empty table.
- **`getImage(n)`** is 1-based; `table[n]` is the same and returns the same value. An index out of range (0, or past
  the end) or an empty slot returns nothing.
- **`getImage(x, y)`** returns the image at column x, row y.
- **`getLength()`** and `#table` give the count; **`getSize()`** returns the cells wide and the rows, as integers
  (3 and 1 for a three-image strip). With no columns, the row count is 0 (on the device (3.1.2, by analysis)).
- **`drawImage(n, x, y, [flip])`** rounds the position.
- **`setImage(n, image)`** stores the image; it shares pixels with the original (see Image identity).
- **`load(path)`** loads into the table's existing buffer. A file with more frames than the table returns false; on
  the device (3.1.2, by analysis) the message is "loaded image table has more frames (n) than allocated buffer
  (m)". On success the length and the cells wide become the file's. `tests/probes/itlen`

### C bitmap tables

- **`newBitmapTable(count, width, height)`** makes a table of `count` cells, but on the device (3.1.2, by analysis), as
  in the Simulator, every cell reports a size of 65535 by 65535 with a row size of 0 until a bitmap is set with
  `setTableBitmap`. Drawing into such a cell writes nothing useful, and drawing it reads memory outside the cell; a
  tilemap built from it has 65535-pixel cells and draws solid black. The result depends on unrelated memory; games
  that work fill their tables with `setTableBitmap` first.
- **`getBitmapTableInfo(table, &count, &cellsWide)`** reports the count; on the device (3.1.2, by analysis) the
  cells-wide value always equals the count.
- **`loadBitmapTable` and `loadIntoBitmapTable`** accept a NULL error pointer.

## Video

### The `.pdv` format

```
header: "Playdate VID" magic, a reserved word, frame count (16 bits), reserved, frame rate (float), width, height
frame table: frame count + 1 words; offset = word >> 2, type = word & 3; the last entry marks the end of the data
each frame: zlib data inflating to height rows of ceil(width / 8) bytes (byte-aligned rows)
types: 0 end of the table; 1 a complete frame; 2 XORed with the previous frame;
       3 combined: a 16-bit length, a complete frame, then a difference frame for the same frame
```

The displayed type 3 frame is its complete frame alone; the difference lets a player step backward. A common mistake
is to XOR the two parts.

### Lua `playdate.graphics.video`

- **`video.new(path)`** loads a `.pdv`; a missing file returns nothing.
- **Queries:** for the SDK's 31-frame test video, `getSize()` is 400 and 240 (integers), `getFrameCount()` 31 and
  `getFrameRate()` 20.0 (a float).
- **Context:** `getContext()` returns a 400 by 240 image the video draws into; `setContext(image)` draws into the given
  image instead; `useScreenContext()` draws to the screen.
- **`renderFrame(n)`** numbers frames from 1 and draws that frame into the context. Out of range it returns false and
  nil.

### C `playdate->graphics->video`

- **`loadVideo(path)`** returns NULL for a missing file. `getInfo` reports width, height, frame rate, frame count and
  current frame (400, 240, 20.0 and 31 for the test video).
- **`setContext(player, bitmap)`** returns 1 and `getContext` returns that bitmap. `renderFrame(player, n)` returns 1,
  or 0 out of range without recording an error (`getError` stays NULL).
- **Video streams (`videostream`):** `newPlayer()` has a video player and a file player from the start
  (`getVideoPlayer`, `getFilePlayer`); `setBufferSize` is accepted; with nothing streamed, `getBufferedFrameCount` and
  `getBytesRead` are 0.
