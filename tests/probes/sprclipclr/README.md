# sprclipclr

sprite.clearClipRectsInRange with a sprite the last update drew, and then with an empty display list after that
sprite was removed: does the game keep running after each call?

Language: Lua. Build: `pdc Source sprclipclr.pdx`.

Notes:

- In the SDK 3.1.1 Simulator the first call is fine. After the second the game stops: the console shows
  `LCDSprite_getBounds: non-NULL value required for argument 's'` and no later update runs, so `expected/sim.txt`
  ends at `cleared with no sprites`. Smaller tests in the Simulator stopped the same way when sprites had been added
  since the last sprite update, or none had been drawn yet, with or without a reference kept to them;
  clearClipRectsInRange before any sprite was created was fine, and so was setClipRectsInRange. The device's
  behaviour is not known yet.
- It stops the game, so it is not part of the probe suite (`tests/device/excluded.txt`); build_bundles.py builds it.
