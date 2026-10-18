# crankacc

getCrankChange's two values while the crank is turned (mouse wheel in the Simulator).

Language: Lua. Build: `pdc Source crankacc.pdx`.

Notes:

- `run.sh <crankacc.pdx> <out.txt>` drives the Simulator crank through its crank field with synthetic X input (`xinput.py`); expected/sim_log.txt is its result.
- `actions.txt` is a mouse-wheel script for `tests/tools/sim/simkeys.sh`.
