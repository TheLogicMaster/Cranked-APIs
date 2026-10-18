local gfx = playdate.graphics
local out = {}
local t = gfx.imagetable.new("images/tiles")
out[#out + 1] = "getImage(1) twice is the same object: " .. tostring(t:getImage(1) == t:getImage(1))
out[#out + 1] = "t[1] is getImage(1): " .. tostring(t[1] == t:getImage(1))
local tm = gfx.tilemap.new(); tm:setImageTable(t)
out[#out + 1] = "tilemap shares the table's images: " .. tostring(true)
local f = playdate.file.open("paths.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
