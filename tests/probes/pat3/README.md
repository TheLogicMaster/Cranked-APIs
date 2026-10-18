# pat3

setPattern phase: one row takes every value 0..255, the others all 0xFF or 0x00.

Language: Lua. Build: `pdc Source pat3.pdx`.

Notes:

- `phase.py <pat3.txt>` (Python 3) prints, for each case (`<base> <row> <value>`), the pattern phases (px, py) that reproduce its pixels: pixel (x, y) shows pattern bit ((x - px) % 8, (y - py) % 8). With two files, `phase.py <a> <b>` prints only the cases whose phases differ.
