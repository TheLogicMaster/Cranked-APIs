-- Probe: where images land at fractional positions, for draw, drawIgnoringOffset, drawCentered, drawAnchored,
-- drawScaled and sprites
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local img = gfx.image.new(3, 3, gfx.kColorBlack)
local target = gfx.image.new(400, 240, gfx.kColorWhite)
local function where()
  local d = target
  for y = 0, 239 do for x = 0, 399 do if d:sample(x, y) == gfx.kColorBlack then return x .. "," .. y end end end
  return "none"
end
local vals = { 10.3, 10.5, 10.7, 10.49, 10.51, -0.3, -0.5, -0.7, 177.3073, 9.999 }
local function case(name, f)
  local r = {}
  for _, v in ipairs(vals) do target:clear(gfx.kColorWhite) gfx.pushContext(target) f(v) gfx.popContext() r[#r + 1] = where() end
  out:write(name .. "\t" .. table.concat(r, " ") .. "\n")
end
gfx.setDrawOffset(0, 0)
case("draw", function(v) img:draw(20 + v, 20 + v) end)
case("drawIgnoringOffset", function(v) img:drawIgnoringOffset(20 + v, 20 + v) end)
gfx.setDrawOffset(5, 5)
case("drawIgnoringOffset+off", function(v) gfx.setDrawOffset(5, 5) img:drawIgnoringOffset(20 + v, 20 + v) end)
case("draw+off", function(v) gfx.setDrawOffset(5, 5) img:draw(20 + v, 20 + v) end)
gfx.setDrawOffset(0, 0)
gfx.setDrawOffset(0, 0)
case("drawCentered", function(v) img:drawCentered(20 + v, 20 + v) end)
case("drawAnchored", function(v) img:drawAnchored(20 + v, 20 + v, 0.5, 0.5) end)
case("drawScaled", function(v) img:drawScaled(20 + v, 20 + v, 2) end)
case("drawRotated", function(v) img:drawRotated(20 + v, 20 + v, 0) end)
case("imagetable draw", function(v) local t = gfx.imagetable.new(1) t:setImage(1, img) t:drawImage(1, 20 + v, 20 + v) end)
case("fillRect", function(v) gfx.fillRect(20 + v, 20 + v, 3, 3) end)
local it = gfx.imagetable.new(1) it:setImage(1, img)
local tm = gfx.tilemap.new() tm:setImageTable(it) tm:setSize(1, 1) tm:setTileAtPosition(1, 1, 1)
case("tilemap draw", function(v) tm:draw(20 + v, 20 + v) end)
case("tilemap drawIgnoringOffset", function(v) tm:drawIgnoringOffset(20 + v, 20 + v) end)
case("drawTiled", function(v) img:drawTiled(20 + v, 20 + v, 3, 3) end)
case("drawFaded", function(v) img:drawFaded(20 + v, 20 + v, 1, gfx.image.kDitherTypeBayer8x8) end)
case("drawBlurred", function(v) img:drawBlurred(20 + v, 20 + v, 0, 1, gfx.image.kDitherTypeNone) end)
case("drawSampled", function(v) img:drawSampled(20 + v, 20 + v, 3, 3, 0.5, 0.5, 1, 0, 0, 1, 0.5, 0.5, 1, 0, false) end)
case("drawRect", function(v) gfx.drawRect(20 + v, 20 + v, 3, 3) end)
case("fillCircleAtPoint", function(v) gfx.fillCircleAtPoint(20 + v, 20 + v, 2) end)
case("drawLine", function(v) gfx.drawLine(20 + v, 20 + v, 25 + v, 20 + v) end)
case("drawText", function(v) gfx.drawText("l", 20 + v, 20 + v) end)
case("fillPolygon", function(v) gfx.fillPolygon(20 + v, 20 + v, 23 + v, 20 + v, 23 + v, 23 + v) end)
local spr = gfx.sprite.new(img)
case("sprite", function(v) spr:moveTo(20 + v, 20 + v) spr:add() gfx.sprite.update() spr:remove() end)
out:close()
function playdate.update() end
