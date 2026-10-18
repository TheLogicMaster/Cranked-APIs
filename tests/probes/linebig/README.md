# linebig

Lines starting above the clip top with extreme coordinates.

Language: Lua. Build: `pdc Source linebig.pdx`.

Notes:

- 400 random lines (fixed seed; end points from -400..799 or from a list of extreme values up to plus or minus 2^31), some under a clip rect or a draw offset. The probe writes no file: it prints one line per case to the console (`<case> <x1> <y1> <x2> <y2> <hash>`, the hash covering every seventh column of the frame), then "linebig done". No expected output is included.
