# Drawing primitives

This file describes how the Playdate draws its primitives: pixels, lines (1-pixel, wide, and width 0), line caps,
rects and their stroke location, rounded rects, ellipses, arcs and pies, circles, triangles and polygons (outlines and
fills), and the colours, patterns and dither patterns they are drawn with. The rules are exact unless marked
otherwise: they match every sampled Simulator image (SDK 3.1.1), including fresh random sets written after the rule,
and the device (3.1.2, by analysis) where that is noted. The drawing target, draw offset, clip rect, stencil, contexts,
the background colour, `clear` and dirty areas are in [display.md](display.md). Bitmaps, image draw modes, scaling,
rotation, sampling, blur and fades are in [images.md](images.md), and text in [text.md](text.md).

## Conventions

- x grows right and y grows down. Pixel (x, y) covers [x, x + 1) by [y, y + 1).
- "Span (y, x0, x1)" means pixels x0 to x1 - 1 of row y (half-open).
- Integer division truncates toward zero, as in C. `>>` is an arithmetic shift.
- "float" means a 32-bit float. Playdate Lua numbers are 32-bit integers and 32-bit floats.
- Coordinates below are drawing coordinates: the draw offset is added before rasterizing, and everything is clipped
  to the clip rect and the target afterwards (see [display.md](display.md)).

## Lua arguments

- **Rounding.** Lua drawing calls read their numbers as floats and round them to the nearest integer, halves away
  from zero: -0.5 becomes -1, 6.5 becomes 7, 10.5 becomes 11. This holds for `fillRect` (x, y, width and height each
  rounded on its own), `drawLine`, `drawPixel`, `fillEllipseInRect`, `fillRoundRect`, `drawCircleAtPoint`,
  `fillTriangle`, polygons and rect objects (`fillRect(geometry.rect.new(13.5, ...))` rounds its fields like plain
  numbers). Probe: `tests/probes/fracq`.
- **`drawRect` rounds its corners**, not its size: it spans round(x) to round(x + w) - 1 (see "Rects" below).
- **Image calls floor** their positions instead (`image:draw` and friends); see [images.md](images.md).
- **`fillPolygon(x1, y1, x2, y2, ...)`** rounds each number the same way as polygon objects. A common mistake is to
  read these with an integer conversion that gives 0 for any non-integer float (as Lua 5.4's `lua_tointeger` does),
  which moves every fractional point to the origin.
- **Integer arguments arrive exactly** where a function takes an integer, including values above 2^24; do not pass
  them through a float. The coordinates of `drawLine`, `fillTriangle` and `drawTriangle` are the exception: these
  read every argument as a float on the device (3.1.2, by analysis), so an integer above 2^24 is rounded to a float
  first.

## Colours

- `kColorBlack` 0, `kColorWhite` 1, `kColorClear` 2, `kColorXOR` 3.
- `kColorXOR` inverts the destination pixels the shape covers. A pixel that a primitive covers twice is inverted
  twice and so is left unchanged; see the corner note under "Rects" for where this is visible.
- `kColorClear` writes transparent pixels into an image that has a mask (it makes it transparent there).
- In Lua `gfx.getColor()` returns a float. `getLineWidth` returns a float too.
- The C API and Lua keep separate drawing settings for some state (draw mode, font, tracking, line cap style,
  background colour); see "Contexts" in [display.md](display.md).

## Pixels

`drawPixel(x, y)` sets one pixel in the current colour or pattern, subject to the clip rect and stencil. Fractional
positions round as above.

## 1-pixel lines

1-pixel lines are 4-connected: there are no diagonal steps.

- The line is drawn row by row from its upper end point (the first point when both have the same y).
- An error term decides how far x moves in each row. Each row is drawn from the previous row's last x to the new x,
  inclusive, so where a step moves in both x and y, the corner pixel along the major axis is filled: horizontally
  first for lines wider than tall, vertically first otherwise.
- Both end points are drawn.
- Lines drawn in opposite directions give the same pixels, because both start from the upper end.

```
stepper(from, to):                     # walks x down a line, one row per step()
    x = from.x; target = to.x; adx = |to.x - from.x|; dy = to.y - from.y   # dy >= 0
    err = (adx >> 1) if adx >= dy else -(dy >> 1)
    step():
        while err >= 0 and x != target: x += sign(to.x - from.x); err -= dy
        err += adx
        return x

line(p, q):
    top, bottom = (p, q) if q.y >= p.y else (q, p)
    s = stepper(top, bottom); prev = top.x
    for y from top.y to bottom.y inclusive:
        new = s.step()
        draw pixels min(prev, new) .. max(prev, new) of row y
        prev = new
```

**Entering the clip rect from above.** When the upper end is above the clip rect's top, the line does not walk the
hidden rows one by one; it jumps to the first visible row in one step. For n hidden rows, with e0 the error before
them:

- e = n * |dx| + e0;
- x moves by k = (dy + e - 1) / dy (truncating division), toward the far end;
- the error becomes e - k * dy;
- drawing then continues row by row.

So the first visible row can hold a single pixel where walking the whole line would have drawn a run. 123 of 856
sampled clipped lines differ if this is not done (`tests/probes/lineclip`; `tests/probes/linebig` covers extreme end
points with clip rects and draw offsets). The jump is not limited to the line's end point: a line whose lower end
is on the clip's top row can draw one pixel beyond that end (`tests/probes/lineclip` has three such lines). A line
whose x range lies entirely outside the clip rect draws nothing (measured, `tests/probes/linewid`). On the device
(3.1.2, by analysis) the jump uses 32-bit arithmetic, so it wraps when n * |dx| exceeds 2^31 (lines tens of
thousands of pixels long).

### Width 0 and negative widths

For lines of width below 2, the width is the extension of each row's run past its end:

- a row covers [prev, new + width) for a line going right or straight down, and [new, prev + width) for a line going
  left, where prev is x before the row's steps and new is x after them;
- width 1 gives the usual inclusive runs;
- width 0 leaves out one end of each run, except that a row in which x does not move still draws its pixel;
- a negative width draws less.

Probe: `tests/probes/polyopen` (54 cases, together with the polygon cases below).

## Wide lines

A line of width 2 or more is a quadrilateral filled by the two-chain scanline fill used for triangles (see
"Triangles"). The quad's offsets across the line are computed in single precision and rounded to whole pixels.

- **Across the line:** the band runs from -w/2 inclusive to +w/2 exclusive, measured toward larger x and y, so an
  even width's extra row or column goes up or left. For horizontal and vertical lines this is exact and easy to check:
  a 2-pixel horizontal line from x = 2 to 13 at y = 3 covers rows 2 and 3, from x = 2 to 12.
- **Butt caps** (`kLineCapStyleButt`, 0, the default) cover the segment from the start inclusive to the end exclusive.
- **Square caps** (`kLineCapStyleSquare`, 1) extend the quad by the same rounded offsets along the line at both ends.
- **Round caps** (`kLineCapStyleRound`, 2) add a filled circle at each end, drawn as `fillEllipse` in the rect
  (end.x - w / 2, end.y - w / 2, w, w) with integer division. So the disc is centred on the end point's pixel centre
  for an odd width and on its top-left pixel corner for an even width.
- **Fractional widths** behave as rounded.
- **Zero-length wide lines** (both end points equal) have no quad: with butt and square caps they draw nothing, and
  with round caps only the two caps. In the formula below the length is 0 (on the device (3.1.2, by analysis) the
  quad is empty); guard the zero length: computing the quad from it gives huge corners that dirty the whole screen.
  Probe: `tests/probes/zeroline`.

```
wide_line(p, q, w):                       # w >= 2
    top, bottom as for line(); dx = bottom.x - top.x; dy = bottom.y - top.y
    if dx == 0 and dy == 0: draw the round caps, if any; return
    L = sqrt(dx*dx + dy*dy)                                   # float
    a  = dy * w / L                                           # float
    ax = int(a + 0.5)
    by = int((a - ax + w) * |dx| / L + 0.5)
    x offsets across the line: cx0 = -(ax / 2), cx1 = ax + cx0
    y offsets across the line: cy0 = -(by / 2), cy1 = by + cy0
    square caps: the quad is also extended along the line: in y by cx0 at the top end and cx1 at the bottom end;
                 in x by cy0 at the top and cy1 at the bottom for a line going right (dx > 0), and by cy1 at the
                 top and cy0 at the bottom otherwise. (sx0, sx1) and (ex0, ex1) below are these extensions at the
                 top (T) and bottom (B) end points, 0 for the other caps
    round caps, drawn first: fillEllipse(end.x - w / 2, end.y - w / 2, w, w) at both ends; each is a separate fill,
                 so with kColorXOR the pixels a cap and the quad share are inverted twice
    the quad, filled with fill_chains (see Triangles) from these two chains:
      dx > 0:  left  T + (cx1 + ex0, cy0 + sx0), T + (cx0 + ex0, cy1 + sx0), B + (cx0 + ex1, cy1 + sx1)
               right T + (cx1 + ex0, cy0 + sx0), B + (cx1 + ex1, cy0 + sx1), B + (cx0 + ex1, cy1 + sx1)
      dx <= 0: left  T + (cx0 + ex1, cy0 + sx0), B + (cx0 + ex0, cy0 + sx1), B + (cx1 + ex0, cy1 + sx1)
               right T + (cx0 + ex1, cy0 + sx0), T + (cx1 + ex1, cy1 + sx0), B + (cx1 + ex0, cy1 + sx1)
```

The C `drawLine(x1, y1, x2, y2, width, color)` takes the width as an argument. Lua's `drawLine(x1, y1, x2, y2,
[width])` and `drawLine(lineSegment, [width])` use the context's line width (`setLineWidth`) unless a width is given
(not nil); a given width is rounded like the coordinates and used as it is, so 0 draws a width-0 line and a negative
width the negative-width pattern (measured, `tests/probes/linewid`). Lua and C keep separate line cap styles
(`setLineCapStyle`).

## Rects

### `fillRect`

- A negative width or height is normalized: (12, 9, -8, -5) fills (4, 4, 8, 5), in Lua and C.
- A width or height of 0 fills nothing.
- In Lua, x, y, width and height are each rounded on their own.

### `drawRect` and the stroke location

The outline is four lines of the line width, with butt ends. In Lua a fifth argument, if given, sets the width instead
of the context's line width, and is truncated. Negative sizes are normalized, and an empty rect draws nothing.

```
t = max(lineWidth, 1); h = t / 2; o = 1 if t is odd else 0
outside stroke: grow the rect by h + o on each side
inside stroke:  shrink the rect by h on each side
centered:       unchanged
top and bottom lines: from round(x - h) to round(x + w + h), less one at the end when t is 1;
                      the top at round(y), the bottom at round(y + height - o)
left and right lines: at round(x) and round(x + w - o),
                      both from round(y + h + o) to round(y + height - h - o)
```

What this covers, by stroke location, for a rect (x, y, w, h):

| Location | Lua constant | Covered |
| --- | --- | --- |
| Centered | `kStrokeCentered` 0 | from x - t/2, w + 2 (t/2) wide (and the same in y) |
| Inside | `kStrokeInside` 1 | inside the rect |
| Outside | `kStrokeOutside` 2 | from x - t, w + 2t wide |

When the stroke covers the whole interior (2t at least the outer width or height), the result is a filled rect.

- A 1-pixel rect covers x through x + w - 1. A width-3 centered stroke covers x - 1 through x + w.
- In Lua `kStrokeInside` is 1 and `kStrokeOutside` is 2; the C header numbers them the other way round. A Lua binding
  has to translate in `setStrokeLocation` and `getStrokeLocation`.
- **Pixels drawn twice.** A 1-pixel `drawRect` draws its sides through the bottom row, so the two bottom corners are
  drawn twice and the top corners once. With `kColorXOR` the bottom corners therefore stay uninverted. Wider strokes
  draw each pixel once. A 1-pixel-high rect's sides run one row past it, so its corners show a pixel below. Probes:
  `tests/probes/xorline` (53 XOR cases), `tests/probes/rectsm`.

## Rounded rects

A filled rounded rect is three rects plus four quarter-ellipse corners, drawn with the ellipse rasterizer below. An
outline is four edge lines with butt caps, centred on the rect's edges, plus four quarter-ellipse arcs drawn with the
line width.

- **Fill radius:** r + 1, at least 2, and at most half of each side (h >> 1, w >> 1). So radius 0 is drawn exactly
  like radius 1 (one corner pixel is cut once both sides are at least 4). In terms of the radius argument, the
  largest radius that has an effect is one less than half the shorter side: a 12 by 8 rect with radius 10 is drawn
  like radius 3 (both become 4 = 8 >> 1).
- **Outline radius:** 0 stays square; otherwise r + 1, clamped to half a side plus half the width. The width is
  clamped to half a side first.
- **Narrow outlines come out solid:** a corner arc whose width reaches its half-axis is filled (see "Ellipse
  outlines"), so an outline 3 pixels wide or high with a radius of 1 or more is solid.
- **Zero and negative sizes:** a zero width or height draws nothing (a `fillRect` with width 0 draws nothing too). A
  negative width or height draws on the other side of x or y, as fills do.
- **Lua stroke location** moves the rect before drawing: inside by lineWidth / 2, outside by lineWidth / 2 rounded
  up. C draws the outline centred on the edge.

```
fillRoundRect(x, y, w, h, r):
    r = max(r + 1, 2); r = min(r, h >> 1, w >> 1); d = 2r
    fillRect(x + r, y, w - 2r, h)
    fillRect(x, y + r, r, h - 2r); fillRect(x + w - r, y + r, r, h - 2r)
    corners: quarter ellipses of size d by d, drawn with line width r (so they come out filled):
        top-left     at (x, y),                  angles 270 to 360
        top-right    at (x + w - d, y),          angles 0 to 90
        bottom-left  at (x, y + h - d),          angles 180 to 270
        bottom-right at (x + w - d, y + h - d),  angles 90 to 180

drawRoundRect(x, y, w, h, r, lw):
    r = 0 if r < 1 else r + 1
    lw = max(lw, 0); lw = min(lw, h >> 1, w >> 1); hl = lw / 2
    r = min(r, (h >> 1) + hl, (w >> 1) + hl); d = 2r
    t = 1 if lw < 2 else 0; o = 1 if lw == 0 else (lw & 1)
    edge lines, width max(lw, 1), butt caps:
        top    from (x - hl + r, y)         to (x + w + hl - r - t, y)
        bottom the same at y + h - o
        left   at x, and right at x + w - o, from y - hl + r to y + h + hl - r - t
    corner arcs as for the fill, placed at (x - hl, y - hl) and so on, size d, line width lw
```

Probes: `tests/probes/rrsmall` (288 cases of radius 0 and 1 and small sizes), `tests/probes/rr2` (300 random fills
and outlines: radii 0 to 20, widths 0 to 9, all stroke locations, negative sizes), `tests/probes/stillopen` (radii 6
to 16 at widths 3 to 8).

## Ellipses

Ellipses are drawn by integer error stepping, not by testing pixel centres. (A pixel-centre model gets within a few
pixels but is not exact; 14 by 14 circles in particular differ.)

### Filled ellipses

A filled ellipse is drawn from the centre row outward, in mirrored pairs of rows; an odd height draws the centre row
once. Each row is one span, whose half-width shrinks under an integer error term. A 14 by 14 ellipse adds 28 to its
starting error, which gives that one size its slightly different shape.

```
fill_ellipse(x, y, w, h):                    # w, h > 0 after flipping negative sizes
    ow = w & 1; oh = h & 1; a = w >> 1; b = h >> 1; cx = x + a; cy = y + b
    err = h * (1 - 2w)
    if oh == 0: err += w*w / h
    if w == 14 and h == 14: err += 28
    k = 4 * w*w / h                            # divided first, then used
    half = a; n = 0; i = -oh
    while i < b:
        x0 = cx - half; x1 = cx + ow + half
        if oh == 0 or n > 0: span(cy - (i + 1), x0, x1); span(cy + n, x0, x1)
        else:                span(cy, x0, x1)          # the centre row of an odd height
        n += 1; i += 1
        if i == b: stop
        err += k * (oh + 2i)
        step = 4h * (ow + 2 half - 2)
        while err >= 0 and half > 0: err -= step; step -= 8h; half -= 1
```

### Ellipse outlines

- A rect with a side under 3 pixels is filled as a rect.
- A line width reaching either half-axis fills the ellipse.
- A negative width draws nothing.
- Widths 0 to 3 use a thin outline that walks from the top row toward the centre. The hole in each row is the
  smallest of the outer half-widths of the last few rows, so the stroke stays thick where the edge is steep. Width 0
  is drawn like width 1 with a slightly different hole.
- Widths 4 and up use two error terms, an outer and an inner ellipse, walking outward from the centre. On
  non-circles the inner axes are computed with a square root so that the stroke keeps its width.

```
thin_outline(x, y, w, h, lw):                # lw from 0 to 3
    ue = 1 if w is even else 0; uh = 1 if h is even else 0
    a = w >> 1; b = h >> 1; cx = x + a; cy = y + b
    err = ue*h + w*w * (1 - 2h) / h
    if uh == 0: err += w*w
    if w == 14 and h == 14: err += 28
    recent = [0, 0, 0]; xi = 0; zero = (lw == 0); lw = max(lw, 1)
    repeat:
        while xi + ue < a and err + 4 * ((2 xi + ue) h + h) < 0:
            err += 4 * ((2 xi + ue) h + h); xi += 1
        inner = min(recent[b % lw], xi - lw + 1)
        if lw >= 2: inner = min(inner, recent[(b + 1) % lw] - (lw - 1))
        if lw == 3: inner = min(inner, recent[(b + 2) % 3] - 1)
        recent[b % lw] = xi + (1 if zero else 0)
        L = cx - ue - xi; Lin = cx - ue - inner + 1; Rin = cx + inner; R = cx + xi + 1
        for row in {cy - b, cy - uh + b} (once when they are the same row):
            if inner < 1: span(row, L, R)
            else: span(row, L, Lin); span(row, Rin, R)
        err -= (4 w*w / h) * (2b - uh - 1); b -= 1
        until b - uh < 0

thick_outline(x, y, w, h, lw):               # lw >= 4
    a, b, cx, cy, ow, oh as for fill_ellipse
    inner height hi = h - 2 lw; inner width wi = w - 2 lw
    on circles the inner ellipse is wi by hi; otherwise the shorter inner axis is
        2a (a - lw) sqrt((1 - lw^2 / b^2) / (a^2 - lw^2))   (or the same with a and b swapped), rounded half up
    the outer ellipse steps as in fill_ellipse; the inner one has its own error term
        f (1 - 2 iw) (+ iw^2 / f for an even height; + 28 for 14 by 14), with iw, f its width and height
    walking the rows outward as in fill_ellipse, each row pair gets
        span(row, cx - a, cx - ih) and span(row, cx + ow + ih, cx + ow + a)     (ih = the inner half-width)
        or a single span once the hole has closed
```

In C, `drawEllipse(x, y, w, h, lineWidth, startAngle, endAngle, color)` draws the stroke inside the rect. `fillEllipse`
with start and end angles of 0 is a full ellipse (a common mistake is to treat 0 to 0 as an empty arc, which loses
every filled circle in a C game).

### Arcs and pies

Angles are in degrees, 0 is up, and they run clockwise. Ranges wrap: 270 to 90 and -90 to 90 are the top half, 350 to
10 is a small arc at the top, and equal angles after reduction (45 and 45, 0 and 360, 90 and 450) mean a full ellipse.

- Each angle a becomes f(a) = (450 - a) mod 360, in [0, 360). Below 180 is the upper half, 180 and up the lower half.
- Which halves the two boundaries fall in gives one of seven layouts: full; end upper and start lower; the reverse;
  both upper (short or wrapping); both lower (short or wrapping).
- Each boundary's x on each row comes from an integer line stepper (the 1-pixel line stepper above) aimed along the
  boundary's angle, and each span of the shape is clipped to the x intervals the layout allows on that row's half.

```
layout(start, end): fe = f(end); fs = f(start); upper(v) = v < 180
    fe == fs:   FULL
    upper(fe):  if upper(fs): (SHORT_UPPER if fe < fs else WRAP_UPPER) else END_UPPER
    otherwise:  if not upper(fs): (SHORT_LOWER if fe < fs else WRAP_LOWER) else START_UPPER

allowed x on the upper half / on the lower half (xs, xe: the start and end boundary x on this row):
    END_UPPER:    (-inf, xe)               / (-inf, xs)
    START_UPPER:  [xs, inf)                / [xe, inf)
    SHORT_UPPER:  [xs, xe)                 / nothing
    WRAP_UPPER:   (-inf, xe) and [xs, inf) / everything
    SHORT_LOWER:  nothing                  / [xe, xs)
    WRAP_LOWER:   everything               / (-inf, xs) and [xe, inf)

boundary x per row: radians = (angle * pi) / 180 as a float; the stepper runs
    for fills and thick outlines: from the centre toward (w sin, |h cos|), one step per row pair;
    for thin outlines: from the rim point (a sin, -|b cos|) toward the centre, stepping only once the row is
    within the stepper's height of the centre
the centre row of an odd height: fills and thick outlines draw it by layout (left part, centre pixel, right part);
    thin outlines treat it as both an upper and a lower row
```

### Lua ellipse and circle calls

- `drawEllipseInRect(x, y, w, h, [startAngle, endAngle], [lineWidth])` and `fillEllipseInRect(x, y, w, h,
  [startAngle, endAngle])` take angles only when both are given. `drawEllipseInRect` takes a line width from one
  extra argument (`(x, y, w, h, lineWidth)` or `(x, y, w, h, start, end, lineWidth)`).
- The rect is read as floats, flipped when its size is negative, grown by the stroke location (lineWidth / 2 for
  centred, lineWidth for outside, nothing for inside), and only then rounded, halves away from zero. The growth
  always uses the context's line width, even when a width argument is passed.
- CoreLibs' `drawCircleAtPoint(x, y, r)`, `fillCircleAtPoint` and `drawArc` draw through these calls with the rect
  (x - r, y - r, 2r, 2r). (A common mistake is to subtract 1 from the width and height, which makes every circle a
  pixel too small.)
- `drawArc` with an arc object draws a counterclockwise arc from its end angle to its start angle. An arc object
  keeps its direction in the field `clockwise` (there is no `direction` field).

Probes: `tests/probes/circ1`, `circw`, `ell14`, `ellw`, `ellint`, `ellf`, `ellfrac`, `ellfrac2` (629 ellipse cases),
`tests/probes/arcs2` (137 arcs, pies and binding cases), `tests/probes/arcs3` (380 fresh random cases).

## Triangles

`fillTriangle` uses a two-chain scanline fill: two chains of vertices start from the top vertex and both go down; each
row, each chain's current edge steps once (with the 1-pixel line stepper), and the row is filled half-open between
them. The bottom row is not drawn. Rows above the clip rect are skipped with the same jump as 1-pixel lines; for
fills this gives exactly the pixels that walking them would.

```
fill_chains(left, right):             # two vertex chains from the same top vertex, both going down
    for each row y from the top vertex's y:
        when y reaches a chain's next vertex, start a new edge from there; stop when a chain ends
        xr = right.edge.step(); xl = left.edge.step()
        span(y, xl, xr)

fill_triangle(p1, p2, p3):
    order the vertices top, mid, bot by y with these tie rules:
        if y1 <= y2 and y1 < y3: top = p1
        elif y2 >= min(y1, y3):  top = p3
        else:                    top = p2
        (mid and bot follow from the same comparisons)
    if cross(mid - top, bot - top) > 0: fill_chains([top, bot], [top, mid, bot])
    else:                               fill_chains([top, mid, bot], [top, bot])
```

`drawTriangle` draws the three edges as lines in the line width.

## Polygons

### Outlines

- **`drawPolygon(polygon, [width])`:** an open polygon is not closed; a closed one gets its closing edge from the last
  point to the first. The optional width (rounded, halves away from zero) replaces the line width. A single point is
  a width by width square at (x - width / 2, y - width / 2).
- **`drawPolygon(x1, y1, ...)`:** always closed, drawn in the line width. Fewer than 2 numbers raises "drawPolygon
  expects at least 2 coordinates".
- Edges are the lines above (1-pixel, width 0, or wide).
- `geometry.polygon.new(point)` with a single point is a one-point polygon.

### Fills

`fillPolygon` fills every polygon with one scanline routine:

1. Collinear and repeated vertices are removed. With fewer than 3 left nothing is drawn; with exactly 3 the triangle
   fill is used.
2. Otherwise rows are scanned downward with a list of active edges. Vertices are taken in (y, x) order:
   - a vertex with no edge ending at it starts two edges, toward both neighbours;
   - a vertex with one edge ending at it continues that edge toward its other neighbour;
   - a vertex with two edges ending at it removes both.
3. Every row, each edge steps once like a 1-pixel line, the edges are kept sorted by x (a stable insertion sort), and
   the spans between them are filled half-open, by the even-odd rule or the nonzero winding rule
   (`setPolygonFillRule`, `kPolygonFillEvenOdd` or `kPolygonFillNonZero`).
4. The polygon's bottom row is not drawn.

```
remove degenerate vertices:
    prev = last vertex; kept = []
    for each vertex v with next vertex n:          # at the wrap, n is read from the compacted list
        if cross(prev - v, n - v) != 0: kept.append(v); prev = v
    if len(kept) < 3: return; if len(kept) == 3: fill_triangle(kept); return

scan:
    order = vertices sorted by (y, x); y = the first vertex's y; edges = []
    loop:
        if y >= the last vertex's y (or the clip bottom): return
        for each vertex v in order with v.y <= y not yet taken:
            ending = edges whose target is v
            two:  remove both
            one:  retarget it from v: toward prev(v) if v.y < prev.y or (v.y == prev.y and v.x < prev.x),
                  else toward next(v)
            none: pos = index of the first edge with x > v.x
                  side = 1 if (prev.y - v.y)(next.x - v.x) <= (next.y - v.y)(prev.x - v.x) else 0
                  insert at pos the pair [edge to next (winding -1), edge to prev (winding +1)] if pos + side is odd,
                  else the pair in the other order
        if y is above the clip rect: advance every edge to the clip top (or its next vertex) at once; continue
        step every edge; sort the edges by x
        even-odd: span(y, edges[0].x, edges[1].x), span(y, edges[2].x, edges[3].x), ...
        nonzero:  from edge i, extend over the following edges until the winding sum returns to 0; fill to there
        y += 1
```

- Fractional points (in polygon objects and in the numbers form) are rounded to nearest, halves away from zero.
- **Errors:** filling an open polygon object raises "Can't fill an open polygon!" on the device (3.1.2, by analysis).
  The Simulator (SDK 3.1.1) never returns from `fillPolygon` on an unclosed `playdate.geometry.polygon`, even a convex
  square (measured); closed objects and the numbers form work. `fillPolygon` with fewer than 6 numbers raises
  "fillPolygon expects at least 3 x,y coordinate pairs".

Probes: `tests/probes/polyq` (60 random quads, half with fractional points), `tests/probes/polyh` (80 polygons of 3
to 6 vertices, including non-monotone ones), `tests/probes/poly2` (160 polygons of 4 to 10 vertices: non-monotone,
self-intersecting and stars, under both rules, with clip rects and draw offsets), `tests/probes/polyopen`.

## Patterns

A pattern replaces the solid colour for primitives: pixel (x, y) of the target takes its value from an 8 by 8 tile.
Patterns are anchored to the target image's origin, not to the draw offset: a rect drawn at x = 3 shows pattern
columns 3 onward.

### Lua `setPattern`

- **Table form, `setPattern(rows, [x, y])`:** 8 pattern rows, then optionally 8 mask rows. A missing row is 0xFF, in
  the pattern and in the mask. Pixel (x, y) shows bit ((x + ox) % 8) of row ((y + oy) % 8), most significant bit
  first and a set bit white, for the pattern and the mask alike.
- **The phase (ox, oy)** comes from the second and third arguments. A missing one is read from the table's values in
  order: with no arguments, ox is row 0 and oy is row 1; with x only, oy is row 0. A missing row counts as 0 here
  (not 0xFF). So `setPattern({0x55, 0xFF, ...})` is shifted by (5, 7) (0x55 mod 8 and 0xFF mod 8). Negative phases
  wrap. This is why some pattern tables look shifted by a column or two compared with their plain bits.
- **Eight integers, `setPattern(r0, ..., r7)`:** opaque, with no phase.
- **Image form, `setPattern(image, x, y)`:** the 8 by 8 block of the image starting at (x, y), not wrapped. Both x
  and y must be given; with x only, the block starts at (0, 0). Beyond the image's edge the Simulator's result is
  unpredictable (mostly black), so that case is undefined.
- **Masked-out pattern pixels** leave the destination as it was (they do not write clear).
- An empty table is the table form with every row missing (all 0xFF), not an image.
- A non-image object raises a Lua argument error.

Probes: `tests/probes/pat2` to `tests/probes/pat7` (4,790 patterns).

### C patterns

- An `LCDPattern` is 16 bytes: 8 rows of pixels and 8 rows of mask, used as an `LCDColor`.
- `setColorToPattern(&color, bitmap, x, y)` makes a pattern colour from the bitmap's 8 by 8 region at (x, y),
  wrapping at the bitmap's edges (unlike Lua's image form).

### Dither patterns: `setDitherPattern(alpha, [type])`

`setDitherPattern` builds an 8 by 8 pattern that draws the current colour on a transparent background.

- **Alpha is transparency:** 0 draws solid colour and 1 draws nothing. This holds for black as well as white. Inside
  Playdate says alpha 0 is transparent for black and that only white is inverted "due to a bug"; the Simulator (SDK
  3.1.1) inverts both (check on hardware).
- **Without a type the type is Bayer 8x8** (`kDitherTypeBayer8x8`). A common mistake is to default to
  `kDitherTypeNone`, which draws everything up to alpha 0.5 and nothing above (Orbeats' `setDitherPattern(0.75)` ring
  disappears). Probe: `tests/probes/dithdef`.
- **Ordered types** (None, DiagonalLine, VerticalLine, HorizontalLine, Screen, Bayer 2x2, 4x4 and 8x8): each type has
  its own 8 by 8 threshold table, and a cell is drawn when alpha * 255 is at most its table value + 0.5. So exactly
  halfway draws: alpha 0.5 with `kDitherTypeNone` draws. The tables are nested (a cell drawn at some alpha is drawn
  at every lower alpha). For the Bayer types this is equivalent to drawing where (m + 0.5) / n^2 < 1 - alpha for the
  standard Bayer matrix entry m at (x mod n, y mod n) of the target; Bayer 2x2 at 0.5 is a checkerboard with (0, 0)
  drawn. The tables are anchored to the target, like other patterns. They were measured at all 256 levels and
  cross-checked by bisecting each cell; they differ from the fade thresholds of [images.md](images.md).
- **Error-diffusion types** (FloydSteinberg, Burkes, Atkinson) depend on more than alpha: they draw nothing in an 8 by
  8 fill but do draw in larger fills, so the pattern presumably comes from diffusing over the filled area. Not
  modelled.

Stencil patterns (`setStencilPattern`) use different thresholds; see [display.md](display.md).

## Performance notes for an implementation

These do not change pixels but keep hostile arguments from hanging an emulator:

- Step lines, chain fills (triangles, polygons, wide lines) and rect fills only over the rows inside the clip rect,
  computing an edge's position at the first visible row directly (in 64-bit arithmetic) rather than walking to it.
  The device (3.1.2, by analysis) itself takes time proportional to the size for some shapes (a line to (2e9, 2e9), a
  huge ellipse).
- Fill whole bytes for solid colours.
- Bounding the work this way does not change the pixels.
