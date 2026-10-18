local out = {}
local a = import './scenes/Home'
out[#out + 1] = "first import: " .. tostring(a and a.name)
local b = import 'scenes/Home'
out[#out + 1] = "second import (same file): " .. tostring(b and b.name) .. " same table " .. tostring(a == b)
local f = playdate.file.open("imp.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
