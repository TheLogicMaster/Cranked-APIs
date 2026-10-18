-- Probe: key order of json.encode and pairs for small string-keyed tables
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
fh:write(json.encode({a = 1, b = {1, 2, 3}, c = "x", d = true}) .. "\n")
local t = {} t.a = 1 t.b = 2 t.c = 3 t.d = 4 t.e = 5
local ks = {} for k in pairs(t) do ks[#ks + 1] = k end fh:write(table.concat(ks, ",") .. "\n")
fh:close()
function playdate.update() end
