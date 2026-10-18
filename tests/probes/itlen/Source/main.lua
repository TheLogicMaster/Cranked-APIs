-- Probe: imagetable length and indexing
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end out:write(table.concat(t, "\t") .. "\n") end
local it = gfx.imagetable.new("assets/marks")
w("len", #it, it:getLength(), it:getSize())
for i = 0, #it + 1 do
  local im = it[i]
  local s = "nil"
  if im then local n = 0 for y = 0, 23 do for x = 0, 23 do if im:sample(x, y) == gfx.kColorBlack then n = n + 1 end end end s = n end
  w("idx", i, im ~= nil, s, it:getImage(i) ~= nil)
end
local sp = gfx.sprite.new()
sp:setImage(it[1])
w("sprite img", sp:getImage() ~= nil)
out:close()
function playdate.update() end
