# cbench

Native speed and memory behaviour (C): register, heap, frame buffer, stack and static buffer stores, a self-modifying code check, and the row padding bytes of bitmaps.

Language: C. Build a mode with: `make device MODE=n`, then `pdc Source mN.pdx` (with PLAYDATE_SDK_PATH set; the build uses Source/pdxinfo).

Notes:

- `make` with no MODE builds mode 7. `make simulator` ignores MODE (the code then defaults to mode 7); for another mode build Source/pdex.so by hand with gcc ... -DMODE=n (see the command in the build log).
- Modes 0-4: 4 million iterations per update (registers only; heap, frame buffer, stack, static buffer stores); compare the time per frame (for example with a runner's per-frame profiling).
- Mode 5: self-modifying code check (logs "smc 5 40 6 41 7 42").
- Mode 6: row padding bytes of bitmaps made in several ways (written to pad.txt), and of selected rows of an ellipse, its mask drawn into a bitmap and a pattern-filled rect (written to pad2.txt); both are logged too.
- Mode 7 (the default): font check. Reads `bitmore.pft` from the pdx and loads it with loadFont, makeFontFromData (the file's contents after its 16-byte header) and makeFontFromData_deprecated, then draws a test string with each and writes the checksums, widths and heights to font.txt (logs "fontq no file" without the font). The font is not included: put a font named `bitmore` in `Source/` (Bitmore Medieval Bold: font-Bitmore-Medieval-Bold.fnt and font-Bitmore-Medieval-Bold-table-8-11.png from the Playdate SDK's `Resources/Fonts/Bitmore/`, renamed to bitmore.fnt and bitmore-table-8-11.png), which pdc compiles to bitmore.pft. In the Simulator (SDK 3.1.1, Linux) the makeFontFromData_deprecated call crashed the Simulator with that font; without that call it wrote "fontq len=1170 loaded=1 made=0 old=0 sum0=b07a3a88 width0=84 h=11".
