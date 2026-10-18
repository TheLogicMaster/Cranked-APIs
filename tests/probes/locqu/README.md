# locqu

getLocalizedText with .strings files (variant of locq).

Language: Lua. Build: `pdc -u Source locqu.pdx` (uncompressed output files).

Notes:

- The same sources and expected output as locq, under a second bundle ID; built with `pdc -u`, so the compiled `.pds` tables are stored uncompressed (locq is built without `-u`). Both give the same results. `graphics/text.md` cites both.
