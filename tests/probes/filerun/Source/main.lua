local out = {}
local ok, r = pcall(playdate.file.run, "themes/retro/retro")
out[#out + 1] = "pcall ok " .. tostring(ok) .. " result type " .. type(r) .. (type(r) == "table" and (" draw " .. type(r.draw) .. " ready " .. tostring(r.ready)) or (" value " .. tostring(r)))
if ok and type(r) == "table" and r.draw then out[#out + 1] = r:draw() end
local f = playdate.file.open("fr.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
