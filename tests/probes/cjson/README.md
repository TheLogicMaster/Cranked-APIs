# cjson

The C API JSON decoder (callback sequence, paths, values, errors, skipping, returnString).

Language: C. Build: `make` (with PLAYDATE_SDK_PATH set).

Notes:

- For inputs 17-19, in every mode (m0, m1, m2 and bare), decoder->path in the error callback is not a valid string: the Simulator returns uninitialised memory there, so it prints arbitrary bytes. expected/sim.txt shows that value as `path=<undefined>`; only the rest of those lines is compared.
