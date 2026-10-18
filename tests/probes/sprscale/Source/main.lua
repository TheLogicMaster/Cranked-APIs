-- Probe: sprite size, bounds and drawn place with a scale
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end fh:write(table.concat(t, " ") .. "\n") end
local function box()
  local img = gfx.getWorkingImage() local x0, y0, x1, y1 = 999, 999, -1, -1
  for y = 0, 239 do for x = 0, 399 do if img:sample(x, y) == gfx.kColorBlack then if x < x0 then x0 = x end if x > x1 then x1 = x end if y < y0 then y0 = y end if y > y1 then y1 = y end end end end
  return x0, y0, x1, y1
end
local u = gfx.image.new("u1")
local c = gfx.image.new("c1")
gfx.setBackgroundColor(gfx.kColorWhite)
for _, im in ipairs({{"u", u}, {"c", c}}) do
  for _, sc in ipairs({{1.5, 1.5}, {0.75, 0.75}, {2, 1.3}, {0.33, 0.6}, {1, 1}, {2.5, 2.5}}) do
    for _, ctr in ipairs({{0.5, 0.5}, {0, 0}, {0.3, 0.8}}) do
      for _, pos in ipairs({{40, 30}, {40.4, 30.6}, {41, 31}}) do
        gfx.clear(gfx.kColorWhite)
        local s = gfx.sprite.new(im[2])
        s:setCenter(ctr[1], ctr[2])
        s:setScale(sc[1], sc[2])
        s:moveTo(pos[1], pos[2])
        s:add()
        gfx.sprite.update()
        local bx = { s:getBounds() }
        local sw, sh = s:getSize()
        w(im[1], sc[1], sc[2], ctr[1], ctr[2], pos[1], pos[2], "size", sw, sh, "bounds", table.concat(bx, ","), "pos", s:getPosition(), "box", box())
        s:remove()
        gfx.sprite.update()
      end
    end
  end
end
fh:close()
function playdate.update() end
