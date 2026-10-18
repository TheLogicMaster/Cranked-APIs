# Writes Source/images/arrow-table-32-32.png: 7 frames of 32x32, a white down-pointing triangle on a transparent
# background, one pixel lower in each frame. Usage: python3 gen.py (run in this folder).
import struct, zlib

W, H, N = 32, 32, 7

def png(path, w, h, px):
    raw = b"".join(b"\0" + bytes(c for p in px[y * w:(y + 1) * w] for c in p) for y in range(h))
    def chunk(t, d): return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))

px = [(0, 0, 0, 0)] * (W * N * H)
for f in range(N):
    for y in range(H):
        for x in range(W):
            ty = y - 6 - f  # triangle rows 0..15: full width 4..27 at the top, a point at the bottom
            if 0 <= ty < 16 and abs(x - 15.5) <= 12 - ty * 0.75:
                px[y * W * N + f * W + x] = (255, 255, 255, 255)
png("Source/images/arrow-table-32-32.png", W * N, H, px)
