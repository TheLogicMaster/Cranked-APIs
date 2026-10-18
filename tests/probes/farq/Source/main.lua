-- Probe: overlaps and queries of sprites far from the origin (cells past 32767 and below -32768)
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function names(list) local t = {} for _, s in ipairs(list) do t[#t + 1] = s.name end return table.concat(t, ",") end
for _, base in ipairs({ 0, 1100000, 2000000, -1100000, 2097152 - 16 }) do
  local list = {}
  for i = 1, 4 do
    local s = gfx.sprite.new() s.name = "s" .. i s:setSize(40, 40) s:setCollideRect(0, 0, 40, 40) s:moveTo(base + i * 15, 100 + i * 5) s:add()
    list[i] = s
  end
  fh:write(base .. " over " .. names(list[2]:overlappingSprites()) .. " all " .. #gfx.sprite.allOverlappingSprites() .. " rect " .. names(gfx.sprite.querySpritesInRect(base, 80, 100, 60)) .. " point " .. names(gfx.sprite.querySpritesAtPoint(base + 40, 112)) .. "\n")
  for i = 1, 4 do list[i]:remove() end
end
fh:close()
function playdate.update() end
