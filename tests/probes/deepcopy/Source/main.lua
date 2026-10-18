import "CoreLibs/object"
local gfx = playdate.graphics
local out = {}
local function log(s) out[#out + 1] = s; local f = playdate.file.open("dc.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close() end
local data = { img = gfx.image.new(8, 8, gfx.kColorBlack), rect = playdate.geometry.rect.new(1, 2, 3, 4) }
local ok, copy = pcall(table.deepcopy, data)
log("deepcopy ok=" .. tostring(ok) .. " sameImage=" .. tostring(ok and copy.img == data.img) .. " imgType=" .. tostring(ok and type(copy.img)))
copy = nil
for i = 1, 5 do collectgarbage("collect") end
local ok2, w = pcall(function() return data.img:getSize() end)
log("original image after copy collected: ok=" .. tostring(ok2) .. " width=" .. tostring(w))
local ok3, s = pcall(function() return data.img:sample(1, 1) end)
log("sample=" .. tostring(ok3) .. " " .. tostring(s))
local img2 = gfx.image.new(8, 8, gfx.kColorWhite)
log("new image after collect: " .. tostring(img2:sample(1, 1)) .. " original still black: " .. tostring(data.img:sample(1, 1)))
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
