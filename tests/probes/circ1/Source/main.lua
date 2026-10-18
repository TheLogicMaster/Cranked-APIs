-- Probe: 1-pixel circle outlines (drawEllipseInRect, square rects) for sizes 1..40, plus a few positions.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(48, 48)
local function case(x, y, w, h)
  img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(1); gfx.drawEllipseInRect(x, y, w, h); gfx.popContext()
  local t = {}; for yy = 0, 47 do for xx = 0, 47 do t[#t + 1] = img:sample(xx, yy) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = string.format("%d %d %d %d|%s", x, y, w, h, table.concat(t))
end
for s = 1, 40 do case(3, 2, s, s) end
for s = 1, 40 do case(4, 5, s, s) end
local fh = playdate.file.open("circ1.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
