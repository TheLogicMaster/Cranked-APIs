# inp

Input queries each frame and every input callback (buttons, crank) under a scripted timeline.

Language: Lua. Build: `pdc Source inp.pdx`.

Notes:

- `sim_actions.txt` is the key script for `tests/tools/sim/simkeys.sh` (Simulator); `timeline.txt` is the same input for an emulator's headless runner (its timeline argument, see "Runner interface" in tests/README.md).
