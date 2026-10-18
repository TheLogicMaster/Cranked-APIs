-- Probe: zero-length lines (both end points equal) at widths 1 to 6 with each cap style, and XOR.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(24, 24)
local caps = { gfx.kLineCapStyleButt, gfx.kLineCapStyleSquare, gfx.kLineCapStyleRound }
for _, w in ipairs({1, 2, 3, 4, 5, 6}) do
  for ci, cap in ipairs(caps) do
    for _, xor in ipairs({false, true}) do
      img:clear(gfx.kColorWhite); gfx.pushContext(img)
      gfx.setColor(xor and gfx.kColorXOR or gfx.kColorBlack); gfx.setLineWidth(w); gfx.setLineCapStyle(cap)
      gfx.drawLine(12, 12, 12, 12)
      if xor then gfx.drawLine(12.3, 11.8, 11.9, 12.2) end
      gfx.popContext()
      local t = {}; for y = 0, 23 do for x = 0, 23 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
      out[#out + 1] = string.format("w%d cap%d %s", w, ci, xor and "xor" or "") .. "|" .. table.concat(t)
    end
  end
end
local fh = playdate.file.open("zeroline.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
