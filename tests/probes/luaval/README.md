# luaval

Argument validation: API calls with odd arguments (each case prints ok or error).

Language: Lua. Build: `pdc Source luaval.pdx`.

Notes:

- No Simulator reference is included; each case must print "ok" or "error" and the host must not crash.
- `assets/beep` (a sound for the "fileplayer negative rate" case) is optional and not included; without it the case falls back to `playdate.sound.fileplayer.new()` with no file.
