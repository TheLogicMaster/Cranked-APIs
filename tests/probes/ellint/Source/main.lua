-- Probe: integer fillEllipseInRect over circle sizes 1..28 and 60 random ellipses (32x32 target).
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(32, 32)
local function case(x, y, w, h)
  img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillEllipseInRect(x, y, w, h); gfx.popContext()
  local t = {}; for yy = 0, 31 do for xx = 0, 31 do t[#t + 1] = img:sample(xx, yy) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = string.format("%d %d %d %d|%s", x, y, w, h, table.concat(t))
end
for s = 1, 28 do case(2, 1, s, s) end
math.randomseed(9)
for i = 1, 60 do case(math.random(0, 3), math.random(0, 3), math.random(1, 28), math.random(1, 28)) end
local fh = playdate.file.open("ellint.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
