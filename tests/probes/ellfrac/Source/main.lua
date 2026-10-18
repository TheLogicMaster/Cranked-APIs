-- Probe: fillEllipseInRect / fillCircleAtPoint / drawCircleAtPoint with fractional positions and sizes, and
-- fractional round rects.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(32, 32)
local function dump(name)
  local t = {}
  for y = 0, 31 do for x = 0, 31 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = name .. "|" .. table.concat(t)
end
local function case(name, fn) img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); fn(); gfx.popContext(); dump(name) end
math.randomseed(3)
for i = 1, 40 do
  local cx, cy, r = 14 + math.random() * 4, 14 + math.random() * 4, 3 + math.random() * 8
  case(string.format("fc %.3f %.3f %.3f", cx, cy, r), function() gfx.fillCircleAtPoint(cx, cy, r) end)
end
for i = 1, 20 do
  local x, y, w, h = 4 + math.random() * 4, 4 + math.random() * 4, 8 + math.random() * 16, 8 + math.random() * 16
  case(string.format("fe %.3f %.3f %.3f %.3f", x, y, w, h), function() gfx.fillEllipseInRect(x, y, w, h) end)
end
for i = 1, 20 do
  local cx, cy, r = 14 + math.random() * 4, 14 + math.random() * 4, 3 + math.random() * 8
  case(string.format("dc %.3f %.3f %.3f", cx, cy, r), function() gfx.drawCircleAtPoint(cx, cy, r) end)
end
for i = 1, 20 do
  local x, y, w, h, r = 2 + math.random() * 4, 2 + math.random() * 4, 10 + math.random() * 16, 6 + math.random() * 16, 1 + math.random() * 5
  case(string.format("frr %.3f %.3f %.3f %.3f %.3f", x, y, w, h, r), function() gfx.fillRoundRect(x, y, w, h, r) end)
end
local fh = playdate.file.open("ellfrac.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
