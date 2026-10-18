-- Probe: the order of sprite query results (point, rect, line, overlapping) with many overlapping sprites
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local seed = 5
local function rnd(n) seed = (seed * 16807) % 2147483647 return seed % n end
local all = {}
for i = 1, 14 do
  local s = gfx.sprite.new() s.name = "s" .. i
  local w, h = 20 + rnd(80), 20 + rnd(60)
  s:setSize(w, h) s:setCollideRect(0, 0, w, h) s:moveTo(100 + rnd(120), 80 + rnd(80)) s:setZIndex(rnd(5)) s:add()
  all[i] = s
end
local function names(list) local t = {} for _, s in ipairs(list) do t[#t + 1] = s.name end return table.concat(t, ",") end
for k = 1, 6 do
  local x, y = 100 + rnd(120), 80 + rnd(80)
  fh:write("point " .. x .. "," .. y .. " " .. names(gfx.sprite.querySpritesAtPoint(x, y)) .. "\n")
  fh:write("rect " .. x .. "," .. y .. " " .. names(gfx.sprite.querySpritesInRect(x - 20, y - 15, 40, 30)) .. "\n")
  fh:write("line " .. names(gfx.sprite.querySpritesAlongLine(x - 90, y - 40, x + 90, y + 40)) .. "\n")
  fh:write("overlap s" .. k .. " " .. names(all[k]:overlappingSprites()) .. "\n")
end
fh:close()
function playdate.update() end
