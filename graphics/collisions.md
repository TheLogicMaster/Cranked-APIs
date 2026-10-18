# Collisions, Geometry and Path Finding

This file covers sprite collisions and the types they use: collide rects, `moveWithCollisions` and the four
collision responses, collision groups and masks, the collision world and its queries (overlaps, point, rect and line
queries, ray info), alpha (pixel) collisions, the `playdate.geometry` types (point, vector2D, size, rect,
lineSegment, arc, polygon, affineTransform), and the `playdate.pathfinder` graphs, nodes and A* search. Sprite
drawing, the display list and dirty rects are in [sprites.md](sprites.md); drawing polygons and arcs is in
[drawing.md](drawing.md); how geometry objects appear to Lua (userdata) is in [../lua/objects.md](../lua/objects.md).

Unless noted, behaviour was measured in the Simulator (SDK 3.1.1). Rules marked "on the device (3.1.2, by analysis)" are
the device's; "the Simulator matches" means the Simulator was also measured to agree. Probes are cited as
`tests/probes/<name>`.

## Which sprites take part

- Only sprites in the display list take part in collisions and queries. `sprite.removeAll()` leaves the collision
  world empty, and a sprite that was never added is never found, even if it has a collide rect. A sprite collected
  by the garbage collector must not linger in the world.
- A sprite with `setCollisionsEnabled(false)`:
  - moves to its goal in `moveWithCollisions` with no collisions;
  - gets an empty table from `overlappingSprites()`;
  - is left out of every pair in `allOverlappingSprites()` (`tests/probes/sprdiff2`).
- A sprite without a collide rect collides with nothing. In the Simulator, `moveWithCollisions` on a sprite whose
  collide rect was cleared crashes.
- `alphaCollision` is the exception: it works on sprites outside the display list (see "Alpha collisions").

## Collide rects

- `setCollideRect(x, y, w, h)` (or a rect) is relative to the sprite's bounds. It is not scaled with the sprite and
  does not flip with the image.
- Rect overlap is strict: two rects that only touch along an edge do not overlap. Compute the overlap from the outer
  edges and require both sides to be positive (a common mistake is to count a rect with one zero side as non-empty,
  or to add the gap between two rects to the width instead of subtracting it; both make everything overlap).

## Groups and masks

`setGroups(groups)` and `setCollidesWithGroups(groups)` take a group number (1 to 32) or a table of them; group n is
bit n - 1 of the mask. A single number must work: reading only tables leaves the mask at 0. `setGroupMask` and
`setCollidesWithGroupsMask` set the masks directly; their getters return floats. Group numbers outside 1 to 32 are
not documented, and their effect was not measured.

The tests (`tests/probes/groupq`, ten combinations):

- **Collisions and `overlappingSprites`:** A collides with B when A's collides-with mask shares a bit with B's group
  mask, or when A's collides-with mask and B's group mask are both 0. So a sprite that is in a group, or that names
  groups to collide with, does not hit a sprite in no group. A mask of 0 does not mean "everything".
- **`allOverlappingSprites`:** a pair counts when either sprite's collides-with mask shares a bit with the other's
  group mask, or when all four masks are 0.

## `moveWithCollisions` and `checkCollisions`

`sprite:moveWithCollisions(goalX, goalY)` (or a point) returns the actual x, y, the collision list and its length.
`checkCollisions` does the same without moving the sprite. The response constants are `kCollisionTypeSlide` 0,
`kCollisionTypeFreeze` 1, `kCollisionTypeOverlap` 2, `kCollisionTypeBounce` 3.

### The response

- The default response of a Lua sprite without `collisionResponse` is **freeze** (bump.lua's default is slide, which
  is wrong here).
- `collisionResponse` may be a constant or a function `(self, other)` returning one. The function (or the C
  `setCollisionResponseFunction` callback) runs only for a collision that was detected, once per collision. A common
  mistake, taken from bump.lua, is to call the filter for every candidate in the cells before testing for a hit; a
  large level can then make hundreds of thousands of calls a frame.

### The resolution loop (on the device (3.1.2, by analysis); the Simulator matches)

Each sprite hit joins a visited list. After a bounce, only the sprite just bounced off is skipped by the next
projection; after any other response, every visited sprite is skipped. A sprite can therefore bounce back and forth
between two others within one move (the SDK collisions example's player made 8 collisions in one call)
(`tests/probes/collq`, `tests/probes/touchq`).

```
visited = [self]; afterBounce = false
repeat:
    candidates = sprites in the cells the move crosses, except self,
                 except (afterBounce ? the last visited sprite : every visited sprite),
                 and except those the group masks rule out
    hits = the candidates the move actually hits, each with response = callback(self, other)
    if there are no hits: stop
    first = the hit with the smallest ti (then the smallest distance)
    add first.other to visited; record the collision
    apply first's response:
        freeze:  stop at the touch point
        overlap: keep going from where this step began, toward the same goal
        slide:   continue from the touch point along the free axis
        bounce:  continue from the touch point, reflected
    afterBounce = (first's response is bounce)
```

There is no limit on the number of responses on the device (3.1.2, by analysis); an emulator should cap it so a sprite
boxed in by bouncing walls cannot hang.

### The collision records

Lua collision info (`tests/probes/collq`, `tests/probes/touchq`, 20 cases with all four responses, several centers
and offset collide rects):

| Field | Meaning |
| --- | --- |
| `sprite`, `other` | the moving sprite and the one hit |
| `type` | the response used |
| `overlaps` | whether they overlapped at the start |
| `ti` | the fraction of the step at which they touch |
| `move` | from where this resolution step began to the touch point, in collide-rect coordinates (touch minus the collide rect's start). For the second collision of a slide, the step begins at the first touch, for example (0, 12.5), not at the original position |
| `normal` | the side hit; for a sprite that starts overlapping and moves, the normal of the side it leaves through, for example (-1, 0), not (0, 0), as in bump.lua |
| `touch`, `slide`, `bounce` | in sprite position coordinates: the internal (collide-rect) point plus the sprite's size times its center. For a centered 15x15 sprite this is 7.5 pixels down and right of the internal point |
| `spriteRect` | the sprite's collide rect at the touch point |
| `otherRect` | the other sprite's collide rect |

C `SpriteCollisionInfo` differs:

- its points are the internal (collide-rect) values, without the center adjustment;
- its `move` is the step's whole movement toward the goal (a probe slide that touches at (10, 2) reports 15, 3), not
  the movement up to the touch.

## The collision world (on the device (3.1.2, by analysis); the Simulator matches)

The order of query results comes from the world's structure, and games can see it (for example taking the first
sprite under the cursor).

- **Cells:** a grid of 32-pixel cells. Cell (cx, cy) covers x from (cx - 1) * 32, counting from 1 as bump.lua does.
- **Cell lists:** each cell keeps its sprites in the order they joined. A sprite joins at the end, at most once.
  Leaving closes the gap. An empty cell is dropped.
- **Updates are incremental:** when a sprite's rect changes, it leaves only the cells it no longer covers and joins
  only the new ones (rows top to bottom, cells left to right). In the cells it keeps, it keeps its place.
- **Point and rect queries:** `querySpritesAtPoint` and `querySpritesInRect` go through the cells of the rect (rows
  top to bottom, cells left to right), each cell's list in order, and keep the first sight of each sprite whose rect
  passes the test (`tests/probes/qorder`, 14 sprites).
- **Cell order:** results come back in an order this model reproduces (measured in the Simulator, `tests/probes/qorder2`
  and `tests/probes/farq`; on the device (3.1.2, by analysis) the same): cells are ordered by a hash of the cell
  coordinates `(cx << 16) | (cy & 0xFFFF)`, mixed by a 32-bit integer hash, over 64 buckets that split and merge as
  cells are added and removed: one bucket splits at a time while there are more cells than half the buckets, and one
  merge happens at a time while there are fewer than an eighth (and more than 64 buckets). Within a bucket, cells keep
  the order they were added; a split keeps that order in both halves, and a merge puts the upper bucket's cells after
  the lower one's. An implementation should keep each cell's real coordinates as well as the packed key: decoding
  positions from the 16-bit fields breaks sprites more than 32,767 cells (about a million pixels) from the origin
  (`tests/probes/farq`).
- **`sprite:overlappingSprites()`** looks up the bucket of each cell the sprite covers, in the same order, and then
  visits every cell chained in that bucket, not only the cell asked for, so cells elsewhere that share the bucket can
  come first. In each cell it takes the sprites in list order; the first visit decides a sprite's place
  (`tests/probes/qorder2`, 90 sprites with moves and removals, enough cells for the table to grow and shrink).
- **`gfx.sprite.allOverlappingSprites()`** takes each sprite in the world in turn and lists each sprite it overlaps,
  found as above, skipping sprites already taken; pairs pass the group rule given earlier. The outer order follows
  memory addresses: it is not stable and cannot be reproduced exactly; following the display list is the practical
  choice (`tests/probes/overlapq`). The pairs themselves match. C `allOverlappingSprites` crashes the Simulator; what
  the device returns is not known; check on hardware.

An emulator also has to bound the work: a sprite whose collide rect covers more than 65,536 cells (16,384 pixels square)
is better kept on one separate list that every query also checks, and queries over huge rects should visit only occupied
cells, in the same order.

## Line queries

- `querySpritesAlongLine(x1, y1, x2, y2)` (or a lineSegment) returns the sprites whose collide rects the segment
  crosses.
- `querySpriteInfoAlongLine` returns the table only, with no count. Each entry has `sprite`, `entryPoint`,
  `exitPoint`, `ti1` and `ti2`.
- The results match the Simulator to the last bit only when the geometry is computed in single precision in the
  device's order (see "Single precision"): `tests/probes/rayq` (200 transformed segments against 11 sprites, every ti,
  entry and exit point).

## Alpha collisions (on the device (3.1.2, by analysis); the Simulator matches)

`sprite:alphaCollision(other)`, `gfx.checkAlphaCollision(image1, x1, y1, flip1, image2, x2, y2, flip2)` and C
`checkMaskCollision` (`tests/probes/alphaq`, `tests/probes/alphaq2`, about 1,800 cases):

- **Sprites:**
  - both need an image; a tilemap sprite or one without an image never collides;
  - a sprite that was never added, or was removed, still collides;
  - the collide rects must overlap; a sprite without a collide rect never collides;
  - the area compared is the intersection of the collide rects, relative to the first sprite's bounds. The second
    image's offset is the difference of the two bounds' float positions, converted toward zero, which is not the
    difference of the rounded positions;
  - each sprite's flip applies, and a scaled or rotated sprite compares the image it shows.
- **Clipping:** the area is clipped to each image's stored pixels (the trimmed rect, mirrored by the flip).
- **Masks:**
  - two images without masks collide whenever the area is not empty;
  - when only one image has a mask, only the first row of the area is read in that image (on the device (3.1.2, by
    analysis) and in the Simulator; games see this);
  - with two masks, every pixel of the area is compared;
  - a fully transparent image never collides, even with an image that has no mask; images that do not touch never
    collide.
- **C `checkMaskCollision`:** an empty rect means the whole first image.
- `alphaCollision(nil)` and a missing argument to `checkAlphaCollision` are argument errors.

## Geometry types

The geometry types are userdata in the Simulator (SDK 3.1.1) (see [../lua/objects.md](../lua/objects.md)): no
custom fields, no `pairs`, `type` returns "userdata". CoreLibs accepts a geometry object in place of numbers by
testing `type(x) == "userdata"`. Every class has `__eq`, so two objects with equal fields compare equal with `==`
(`tests/probes/arceq`). The class tables have a `userval_count` of 0. There is no `playdate.geometry.polygonEdges`.

### Fields are floats

Every numeric field of a rect, point, size, vector2D, lineSegment, arc or affineTransform is a float, after
construction and after assigning an integer: `r.x = 7` reads back as `7.0`. A numeric string is converted:
`p.x = "5"` reads back as `5.0` (`tests/probes/geoflt`). `polygon:count()` is an integer. Text a game builds from
these values shows "7.0", so the type matters.

### Field aliases

Besides the documented fields, geometry objects answer to short aliases, for reading and writing
(`tests/probes/rectq`):

- `rect.w`, `rect.h` are `width`, `height`;
- `size.w`, `size.h` are `width`, `height`;
- `lineSegment.x`, `lineSegment.y` are `x1`, `y1`;
- `arc.r` is `radius`;
- an arc keeps its direction in `clockwise` (there is no `direction` field).

### Single precision

Lua numbers are single precision on the device (3.1.2, by analysis), and the geometry functions convert angles in a
fixed order. The forms below are equal in exact arithmetic but differ in the last bit otherwise, enough to move a ray's
entry point across a pixel boundary (`tests/probes/f32q`, 129 values):

- `affineTransform:rotate` and `rotatedBy`: `(degrees * pi) / 180`;
- `skew` and `skewedBy`: the same for each angle;
- `vector2D.newPolar(length, angle)`: `a = ((angle - 90) / 180) * pi`, giving `(length * cos a, length * sin a)`;
- `angleBetween`: `(atan2(b) - atan2(a)) * 180 / pi`, then moved into (-180, 180].

### point, size and vector2D

- `point - vector` is a point. All other `point` and `size` functions behave as documented.
- `vector2D.newPolar(length, angle)`: 0 degrees points up and angles run clockwise (the formula above).
- `angleBetween` returns degrees.
- `normalize` leaves a zero vector unchanged (no NaN); `normalized` exists and returns a new vector.
- `leftNormal` and `rightNormal` are unit length.

### rect

- Rects that only touch do not intersect: `intersects` is false for touching edges.
- `intersection` and `rect.fast_intersection` with no overlap give (0, 0, 0, 0).
- `rect.fast_union` returns x, y, width and height (not the right and bottom edges); its values are floats, as are
  `fast_intersection`'s.
- `offsetBy` keeps the size.
- `containsRect` accepts four numbers as well as a rect.
- `toPolygon()` returns a closed polygon.
- Construction, fields, union, inset, offset, containment, flipping and `tostring` behave as documented.
- A rect passed to a drawing call rounds its fields like plain numbers (see [drawing.md](drawing.md)).

### lineSegment

- `lineSegment.fast_intersection(x1, y1, x2, y2, x3, y3, x4, y4)` returns whether the segments cross, and where.
  (A symmetric test case hides the usual sign mistake: compute the point from the first segment's start plus t times
  the first segment's direction.)
- `intersectsLineSegment`, `intersectsPolygon` and `intersectsRect` return whether they cross and the crossing points,
  ordered along the line.
- `closestPointOnLineToPoint` stays on the segment (clamped at the ends).
- `tostring` puts two spaces between the two points.

### arc

`arc.new(x, y, radius, startAngle, endAngle, [clockwise])`. An arc's span runs in its direction
(`tests/probes/arcg`, 20 arcs):

```
span = clockwise ? end - start : start - end
while span < 0: span = span + 360        -- not reduced when above 360
```

So 45 to 290 counterclockwise is 115 degrees, 350 to 10 clockwise is 20, 0 to 360 clockwise is 360 but
counterclockwise 0, and 0 to 720 clockwise is 720. `length()` and `pointOnArc(distance, [extend])` both follow it;
`pointOnArc` stops at the span unless `extend` is true. (Using |end - start| for both directions sends
counterclockwise arcs that cross 0 the long way round.) CoreLibs' `drawArc(arc)` draws a counterclockwise arc from
its end angle.

### polygon

- `polygon.new(n)` makes n points at the origin, open. `polygon.new(point)` with a single point object is a
  one-point polygon, not a count.
- A polygon whose last point repeats the first is closed, and `count()` excludes the repeat.
- `close()` marks it closed without adding a point. "Closed" must be an explicit flag: inferring it from the last
  point equaling the first makes empty polygons look closed and `close()` ineffective.
- The closing edge counts in `length`, `pointOnPolygon`, intersections and drawing.
- `pointOnPolygon(d, true)` extends past the end.
- `getBounds()` returns x, y, width and height; `getBoundsRect()` the same as a rect.
- `copy()` makes independent points, so `polygon * transform` leaves the original alone.
- `count()` returns an integer; `getPointAt` and `setPointAt` coordinates are floats.
- On the device (3.1.2, by analysis), `#` on a polygon (or any geometry object) raises an error unless its class defines
  `__len`.
- Drawing: an open polygon is not closed by `drawPolygon`, and `fillPolygon` of an open polygon is the error
  "Can't fill an open polygon!" (see [drawing.md](drawing.md)). In the Simulator, filling an unclosed polygon object
  never returns.

### affineTransform

- `transformPolygon` exists alongside `transformedPolygon`.
- Composition order, `invert`, `transformAABB`, `transformLineSegment` and the rest behave as documented, given the
  single-precision angle rules above.
- `tostring` separates columns with tabs.

## Path finding

`playdate.pathfinder.graph` and `playdate.pathfinder.node` are userdata. Setting a field a node does not have is the
error "Could not set value for 'foo' on playdate.pathfinder.node" (a number key is named by its number, `'1'`);
reading an unknown field gives nil. A graph has no `__newindex` at all. A node's `id`, `x` and `y` are floats, and
paths report IDs as floats. Nodes keep one Lua value each (the same value every time a node is returned).

### Graphs and nodes

- `graph:addNewNodes(n)` numbers the new nodes after the highest ID in use, starting at 1.
- `graph.new(count, coordinates)` reports each node's coordinates one higher than given, with (1, 1) as the default
  (measured). `addNewNode(id, x, y)` and `setXY` store coordinates as given.
- `addConnections{ [id] = { otherId, weight, ... } }` connects each listed node.
- Connections are listed in the order they were added.
- `graph:nodeWithID(id)` returns that node, or nil. Removing a node, `addConnectionToNodeWithID`,
  `setXYForNodeWithID` and `node:setXY` all rely on it.
- A node freed while another still lists it as a connection must not be used afterwards; `removeNode(nil)` and nil
  nodes in `addNode`, `addNodes` and connections are errors.
- An emulator should limit graph sizes in `new2DGrid`, `graph.new` and `addNewNodes`, checking before allocating.

### `graph.new2DGrid(width, height, allowDiagonals, [includedNodes])`

Each included node connects to its included neighbors, scanned row by row: the row above, its own row, then the row
below, each left to right. The center of a 3 by 3 grid lists [2, 4, 6, 8] (without diagonals). Diagonals toward the
lower left are included when diagonals are allowed. Excluded nodes have no connections.

### `findPath` and `findPathWithIDs` (on the device (3.1.2, by analysis); the Simulator matches)

`graph:findPath(start, goal, [heuristic], [findPathToGoalAdjacentNodes])` returns the nodes from start to goal,
start first, or nil; `findPathWithIDs` the IDs. The search (`tests/probes/pathq`, 12 random searches on 4- and
8-connected grids with and without heuristics and adjacency, plus a weighted hand-built graph):

```
for every node: not yet visited, no parent
start.g = 0; start.h = H(start, goal)
open = [start]                        -- kept in decreasing f = g + h
while open is not empty:
    current = the last node of open   -- smallest f; the latest inserted among equals
    remove it from open
    if current is goal: stop
    if adjacent-goal mode and current is one step from goal in x or in y: stop
    for each connection (other, weight) of current, in connection order:
        tentative = current.g + weight
        if other is not yet visited: other.h = H(other, goal); other.g = tentative
        else if tentative < other.g: take other out of open and closed
        if other is in neither open nor closed:
            other.g = tentative; other.parent = current
            insert other into open after every node whose f is not smaller
    close current
path = the last node taken, followed back through its parents, reversed so start comes first
```

- H is the game's heuristic function, or |dx| + |dy| of the node coordinates by default. A supplied heuristic must
  be called.
- The adjacency test is "one step in x or in y" even on 8-connected grids.
- Start equal to goal gives the one-node path.
- With no path, the result is nil. In adjacent-goal mode a goal that cannot be entered still gives the path to its
  neighbor.
- Path costs wrap at 16 bits.
- Ties between equally short paths go to the most recently inserted node: a 3 by 3 grid from 1 to 9 gives
  [1, 4, 7, 8, 9], and with the adjacent-goal flag [1, 4, 7, 8].
