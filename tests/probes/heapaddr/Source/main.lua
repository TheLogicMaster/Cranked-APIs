local out = {}
local keep = {}
local addrs = {}
for i = 1, 6 do local t = {}; keep[i] = t; addrs[#addrs + 1] = tostring(t):match("0x%x+") or tostring(t) end
out[#out + 1] = "tables: " .. table.concat(addrs, " ")
local gaps = {}
for i = 2, #addrs do gaps[#gaps + 1] = tostring(tonumber(addrs[i]) - tonumber(addrs[i - 1])) end
out[#out + 1] = "gaps: " .. table.concat(gaps, " ")
local fh = playdate.file.open("gf.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
