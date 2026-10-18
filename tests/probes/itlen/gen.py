# Writes Source/assets/marks-table-24-24.png: 3 frames of 24x24 on a transparent background: a black disc, a black
# square with a white border, a black cross. Usage: python3 gen.py (run in this folder).
import struct, zlib

W, H, N = 24, 24, 3

def png(path, w, h, px):
    raw = b"".join(b"\0" + bytes(c for p in px[y * w:(y + 1) * w] for c in p) for y in range(h))
    def chunk(t, d): return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))

BLACK, WHITE, CLEAR = (0, 0, 0, 255), (255, 255, 255, 255), (0, 0, 0, 0)

def mark(f, x, y):
    if f == 0: return BLACK if (x - 11.5) ** 2 + (y - 11.5) ** 2 <= 81 else CLEAR
    if f == 1:
        if 4 <= x < 20 and 4 <= y < 20: return BLACK if 6 <= x < 18 and 6 <= y < 18 else WHITE
        return CLEAR
    return BLACK if (abs(x - y) <= 1 or abs(x + y - 23) <= 1) and 3 <= x <= 20 else CLEAR

px = [mark(f, x, y) for y in range(H) for f in range(N) for x in range(W)]
png("Source/assets/marks-table-24-24.png", W * N, H, px)
