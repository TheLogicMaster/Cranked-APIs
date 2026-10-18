# disppl

Whether getDisplayImage always returns the previous frame: each frame encodes its number in 16 pixels and reads back
the number shown, over 600 frames, some of them slow on purpose.

Language: Lua. Build: `pdc Source disppl.pdx`.

Notes:

- It writes nothing until frame 600, so the probe suite waits for it: `suite_idle=650`.
