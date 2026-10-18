-- Probe: rotated sprites' size, bounds and the area they draw and clear
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function bbox(img, pred)
  local x0, y0, x1, y1 = 999, 999, -1, -1
  for y = 0, 89 do for x = 0, 119 do if pred(img:sample(x, y)) then if x < x0 then x0 = x end if x > x1 then x1 = x end if y < y0 then y0 = y end if y > y1 then y1 = y end end end end
  return x0 .. "," .. y0 .. "," .. x1 .. "," .. y1
end
local u = gfx.image.new("u1")
local circ = gfx.image.new(17, 17, gfx.kColorClear)
gfx.pushContext(circ) gfx.setColor(gfx.kColorBlack) gfx.fillCircleAtPoint(8, 8, 8) gfx.popContext()
gfx.setBackgroundColor(gfx.kColorWhite)
for _, im in ipairs({{"u", u}, {"c", circ}}) do
  for _, rot in ipairs({{30, 1}, {45, 1}, {90, 1}, {30, 1.3}, {0, 1.5}, {200, 0.8}, {10, 2}}) do
    for _, pos in ipairs({{40, 30}, {40.5, 30.5}, {40.3, 30.7}, {41.75, 30.25}}) do
      local img = gfx.image.new(120, 90, gfx.kColorClear)
      gfx.pushContext(img)
      local s = gfx.sprite.new(im[2])
      s:setRotation(rot[1], rot[2])
      s:moveTo(pos[1], pos[2]) s:add() gfx.sprite.update() s:remove()
      gfx.popContext()
      gfx.sprite.update()
      local w, h = s:getSize()
      fh:write(im[1] .. " " .. rot[1] .. " " .. rot[2] .. " " .. pos[1] .. " " .. pos[2] .. " size " .. w .. "," .. h .. " bounds " .. table.concat({s:getBounds()}, ",") .. " drawn " .. bbox(img, function(c) return c == gfx.kColorBlack end) .. " cleared " .. bbox(img, function(c) return c ~= gfx.kColorClear end) .. "\n")
    end
  end
end
fh:close()
function playdate.update() end
