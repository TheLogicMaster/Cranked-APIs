# netq

Network, server time, launcher and other system functions, without network permission.

Language: Lua. Build: `pdc Source netq.pdx`.

Notes:

- The probe writes `out.txt` line by line (flushed after each line).
- `expected/sim.txt` is a run left alone: at `http.new` the Simulator asks for network permission and waits, so the file stops after `getStatus`.
- `expected/sim_answered.txt` is a run where the permission prompt was answered without granting access: `http.new` and the other constructors return nil, the server time callback gets an error, and `frame60` is reached. It has no `argv` or `chsrc` lines and starts at `consts`.
