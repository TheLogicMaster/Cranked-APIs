-- Probe: setPattern phase. One row takes every value 0..255; the other rows are all 0xFF or all 0x00.
-- Each pattern fills a 16x16 image; the dump is the 16x16 result (1 = black).
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(16, 16)
for _, base in ipairs({ 0xFF, 0x00 }) do
  for row = 0, 7 do
    for v = 0, 255 do
      local p = {}; for i = 0, 7 do p[i + 1] = (i == row) and v or base end
      img:clear(gfx.kColorWhite)
      gfx.pushContext(img); gfx.setPattern(p); gfx.fillRect(0, 0, 16, 16); gfx.popContext()
      local t = {}
      for y = 0, 15 do for x = 0, 15 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
      out[#out + 1] = base .. " " .. row .. " " .. v .. "|" .. table.concat(t)
    end
  end
end
local fh = playdate.file.open("pat3.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
