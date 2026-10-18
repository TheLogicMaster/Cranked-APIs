# numtype

Whether the numbers returned by argument-free getters are integers or floats.

Language: Lua. Build: `pdc Source numtype.pdx`.

Notes:

- The getSecondsSinceEpoch, getTime and getGMTTime values are the time of the run, and the file.modtime values the time main.pdz was built, so expected/sim.txt shows them as placeholders such as `<year>` and `<n>`; only their form (field names and integer or float type) is compared.
