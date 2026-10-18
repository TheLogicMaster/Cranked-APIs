# mtleak

Swapped metatables on native objects - leaks, and another type's __gc on an object.

Language: Lua. Build: `pdc Source mtleak.pdx`.

Notes:

- Mode 1 (the default) gives 6,000 new images an empty metatable, which drops their `__gc`. Mode 2 gives them a synth's metatable instead, so a synth's `__gc` runs on images. Each run writes one line to `out.txt` at frame 31 (`mode <n> lua KB <count>`); the host must not crash.
- Mode 2 runs when a file named `mode2` exists, found by `playdate.file.exists` in the game's data folder or in the pdx: create an empty `mode2` in the data folder (or put one in `Source/`) to select it, and delete it for mode 1.
- No expected output is included.
