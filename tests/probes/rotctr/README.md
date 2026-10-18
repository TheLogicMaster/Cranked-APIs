# rotctr

drawRotatedBitmap with off-centre centers at scales above and below 4 megapixels, and a scale of 1e30.

Language: C. Build: `make` (with PLAYDATE_SDK_PATH set).

Notes:

- `run.sh <rotctr.pdx> <runner>` runs it in an emulator's headless runner and compares out.raw with expected/expected.raw, the Simulator's pixels for all 7 frames.
