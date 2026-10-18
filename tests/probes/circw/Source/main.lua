-- Probe: wide circle outlines (centered stroke) for odd and even sizes 5..39, widths 2..5.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(56, 56)
for _, w in ipairs({2, 3, 4, 5}) do
  for s = 5, 39, 2 do
    for _, size in ipairs({s, s + 1}) do
      img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(w); gfx.drawEllipseInRect(7, 6, size, size); gfx.popContext()
      local t = {}; for yy = 0, 55 do for xx = 0, 55 do t[#t + 1] = img:sample(xx, yy) == gfx.kColorBlack and "1" or "0" end end
      out[#out + 1] = string.format("%d %d|%s", w, size, table.concat(t))
    end
  end
end
local fh = playdate.file.open("circw.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
