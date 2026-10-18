-- Probe: the area a sprite update clears (background) for sprites at fractional bounds
import "CoreLibs/sprites"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function bbox(img, pred)
  local x0, y0, x1, y1 = 999, 999, -1, -1
  for y = 0, 89 do for x = 0, 119 do if pred(img:sample(x, y)) then if x < x0 then x0 = x end if x > x1 then x1 = x end if y < y0 then y0 = y end if y > y1 then y1 = y end end end end
  return x0 .. "," .. y0 .. "," .. x1 .. "," .. y1
end
local u = gfx.image.new("u1")
gfx.setBackgroundColor(gfx.kColorWhite)
for _, sz in ipairs({{21, 15}, {20, 14}}) do
  local im = gfx.image.new(sz[1], sz[2], gfx.kColorBlack)
  for _, x in ipairs({40, 40.25, 40.5, 40.75, 41}) do
    for _, y in ipairs({30, 30.5, 30.3}) do
      for _, sc in ipairs({1, 1.5}) do
        local img = gfx.image.new(120, 90, gfx.kColorClear)
        gfx.pushContext(img)
        local s = gfx.sprite.new(im)
        if sc ~= 1 then s:setScale(sc) end
        s:moveTo(x, y) s:add() gfx.sprite.update() s:remove()
        gfx.popContext()
        gfx.sprite.update()
        fh:write(table.concat({sz[1], sz[2], x, y, sc}, " ") .. " bounds " .. table.concat({s:getBounds()}, ",") .. " drawn " .. bbox(img, function(c) return c == gfx.kColorBlack end) .. " cleared " .. bbox(img, function(c) return c ~= gfx.kColorClear end) .. "\n")
      end
    end
  end
end
for _, sz in ipairs({{20.5, 14.3}, {20.9, 14.9}, {20.1, 14.1}}) do
  for _, x in ipairs({40, 40.25, 40.5, 40.75}) do
    local img = gfx.image.new(120, 90, gfx.kColorClear)
    gfx.pushContext(img)
    local s = gfx.sprite.new()
    s:setSize(sz[1], sz[2])
    s.draw = function(self, dx, dy, dw, dh) gfx.setColor(gfx.kColorBlack) gfx.fillRect(-5, -5, 100, 100) fh:write("  draw " .. table.concat({dx, dy, dw, dh}, ",") .. "\n") end
    s:moveTo(x, 30.4) s:add() gfx.sprite.update() s:remove()
    gfx.popContext()
    gfx.sprite.update()
    fh:write(table.concat({sz[1], sz[2], x}, " ") .. " bounds " .. table.concat({s:getBounds()}, ",") .. " drawn " .. bbox(img, function(c) return c == gfx.kColorBlack end) .. " cleared " .. bbox(img, function(c) return c ~= gfx.kColorClear end) .. "\n")
  end
end
fh:close()
function playdate.update() end
