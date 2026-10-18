# rr_const

Every k* constant under playdate (case suite 5).

Language: Lua. Build: `pdc Source rr_const.pdx`.

Notes:

- Output: out5.txt in the data folder (appended; skip.txt skips cases). expected/sim_out5.txt is the Simulator run.
- The probe imports no CoreLibs, so `kTextAlignment` (a CoreLibs global) does not exist and its three cases are not written.
