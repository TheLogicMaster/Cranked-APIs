-- Probe: one ellipse rect given as integers and as fractions that round to it.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(32, 32)
local function case(name, fn)
  img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); fn(); gfx.popContext()
  local t = {}; for y = 0, 31 do for x = 0, 31 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = name .. "|" .. table.concat(t)
end
case("int 10 8 14 14", function() gfx.fillEllipseInRect(10, 8, 14, 14) end)
for _, w in ipairs({13.5, 13.6, 13.82, 14.0, 14.2, 14.49}) do
  case("w " .. w, function() gfx.fillEllipseInRect(10, 8, w, w) end)
end
for _, x in ipairs({9.5, 9.7, 10.3, 10.49}) do
  case("x " .. x, function() gfx.fillEllipseInRect(x, 8, 14, 14) end)
end
local fh = playdate.file.open("ellfrac2.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
