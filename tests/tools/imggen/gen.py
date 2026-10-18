# Writes the generated test images that several probes share (simple shapes, black, white and transparent pixels),
# into each probe's Source/ folder. Usage: python3 gen.py (from any folder).
#   figure.png             247x150: rotxy, rotscl. An asymmetric figure with transparent margins of different widths
#                          (pdc trims them), a dithered area, solid shapes, a white disc with a black outline, and holes.
#   cursor.png             24x24: sprupq, sprbgq, sprrotq, spradddraw. An arrow cursor pointing up and left (black
#                          outline, white fill) on a transparent background, so rotations and flips are visible.
#   panel.png              350x155: sprrotq. A rounded panel (transparent corners, 2-pixel black border, white inside)
#                          with an off-centre black triangle, bar and ring.
#   marks-table-24-24.png  3 frames of 24x24: sprimg, sprmode. The same table as probes/itlen (a black disc, a black
#                          square with a white border, a black cross) on a transparent background.
import os, struct, zlib

PROBES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "probes")
B, W, T = (0, 0, 0, 255), (255, 255, 255, 255), (0, 0, 0, 0)

def png(path, w, h, px):
    raw = b"".join(b"\0" + bytes(c for p in px[y * w:(y + 1) * w] for c in p) for y in range(h))
    def chunk(t, d): return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))

def figure(x, y):
    # content box: x 3..240, y 2..145 (margins 3 left, 6 right, 2 top, 4 bottom)
    if not (3 <= x <= 240 and 2 <= y <= 145): return T
    if (x - 60) ** 2 + (y - 50) ** 2 <= 30 ** 2: return W if (x - 60) ** 2 + (y - 50) ** 2 <= 27 ** 2 else B
    if 110 <= x <= 230 and 10 <= y <= 70:                       # dithered block with a transparent notch
        if x >= 200 and y <= 30: return T
        return B if (x + y) % 2 == 0 else W
    if 15 <= x <= 25 and 85 <= y <= 145: return B               # an "F": stem and two bars of different lengths
    if 15 <= x <= 80 and 85 <= y <= 95: return B
    if 15 <= x <= 55 and 110 <= y <= 119: return B
    if 100 <= x <= 230 and 90 <= y <= 140 and (x - 100) * 50 >= (140 - y) * 130: return B   # right triangle
    if 3 <= x <= 240 and y == 2: return B                       # a 1-pixel top edge line
    if (x * 7 + y * 3) % 23 == 0 and 90 <= y: return W          # sparse white specks
    return T

def cursor(x, y):
    # arrow tip at (2, 2): a triangle along the top-left diagonal plus a tail towards the lower right
    def inside(x, y, m):
        head = x >= 2 + m and y >= 2 + m and (x - 2) + (y - 2) <= 15 - m and abs(x - y) <= 9 - m
        tail = abs(x - y) <= 2 - m and 8 <= x + y - 4 <= 34 - 2 * m and x >= 7 and y >= 7
        return head or tail
    if inside(x, y, 1): return W
    if inside(x, y, 0): return B
    return T

def panel(x, y):
    w, h, r = 350, 155, 12
    cx = r if x < r else (w - 1 - r if x > w - 1 - r else x)
    cy = r if y < r else (h - 1 - r if y > h - 1 - r else y)
    d2 = (x - cx) ** 2 + (y - cy) ** 2
    if d2 > r * r: return T
    if d2 > (r - 2) ** 2 or x < 2 or y < 2 or x > w - 3 or y > h - 3: return B
    if 15 <= x <= 60 and 15 <= y <= 15 + (60 - x): return B             # triangle in the top-left corner
    if 120 <= x <= 300 and 120 <= y <= 127: return B                    # bar near the bottom
    if 18 ** 2 <= (x - 250) ** 2 + (y - 55) ** 2 <= 24 ** 2: return B   # ring right of centre
    return W

def mark(f, x, y):
    if f == 0: return B if (x - 11.5) ** 2 + (y - 11.5) ** 2 <= 81 else T
    if f == 1:
        if 4 <= x < 20 and 4 <= y < 20: return B if 6 <= x < 18 and 6 <= y < 18 else W
        return T
    return B if (abs(x - y) <= 1 or abs(x + y - 23) <= 1) and 3 <= x <= 20 else T

def write(name, w, h, fn, probes):
    px = [fn(x, y) for y in range(h) for x in range(w)]
    for p in probes: png(os.path.join(PROBES, p, "Source", name), w, h, px)

write("figure.png", 247, 150, figure, ["rotxy", "rotscl"])
write("cursor.png", 24, 24, cursor, ["sprupq", "sprbgq", "sprrotq", "spradddraw"])
write("panel.png", 350, 155, panel, ["sprrotq"])
write("assets/marks-table-24-24.png", 72, 24, lambda x, y: mark(x // 24, x % 24, y), ["sprimg", "sprmode"])
