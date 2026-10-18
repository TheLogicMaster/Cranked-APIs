-- Probe: query and overlapping order with enough sprites and cells for the cell table to grow and shrink, after
-- moves and removals (the qorder probe covers the small case)
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local seed = 11
local function rnd(n) seed = (seed * 16807) % 2147483647 return seed % n end
local all = {}
local function names(list) local t = {} for _, s in ipairs(list) do t[#t + 1] = s.name end return table.concat(t, ",") end
for i = 1, 90 do
  local s = gfx.sprite.new() s.name = "s" .. i
  local w, h = 8 + rnd(120), 8 + rnd(90)
  s:setSize(w, h) s:setCollideRect(0, 0, w, h) s:moveTo(rnd(800) - 200, rnd(600) - 150) s:add()
  all[i] = s
end
local function report(tag)
  for i = 1, #all, 3 do
    local s = all[i]
    if s then fh:write(tag .. " " .. s.name .. " " .. names(s:overlappingSprites()) .. "\n") end
  end
  for k = 1, 8 do
    local x, y = rnd(800) - 200, rnd(600) - 150
    fh:write(tag .. " rect " .. names(gfx.sprite.querySpritesInRect(x, y, 150, 110)) .. "\n")
    fh:write(tag .. " point " .. names(gfx.sprite.querySpritesAtPoint(x, y)) .. "\n")
  end
end
report("a")
for i = 1, 90, 2 do all[i]:moveBy(rnd(140) - 70, rnd(140) - 70) end
report("b")
for i = 1, 90 do if i % 4 ~= 0 then all[i]:remove() end end
local keep = {} for i = 1, 90 do if i % 4 == 0 then keep[#keep + 1] = all[i] end end
all = keep
report("c")
for i = 1, #all do all[i]:moveTo(rnd(400), rnd(240)) end
report("d")
fh:close()
function playdate.update() end
