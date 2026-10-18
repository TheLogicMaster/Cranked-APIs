-- Probe: random wide lines (widths 2 to 8) with butt, square, and round caps.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local W, H = 48, 40
local img = gfx.image.new(W, H)
math.randomseed(2024)
local caps = { gfx.kLineCapStyleButt, gfx.kLineCapStyleSquare, gfx.kLineCapStyleRound }
for i = 1, 120 do
  local w = math.random(2, 8)
  local x1, y1, x2, y2 = math.random(10, 38), math.random(10, 30), math.random(10, 38), math.random(10, 30)
  local cap = (i % 3) + 1
  gfx.pushContext(img); gfx.clear(gfx.kColorWhite); gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(w); gfx.setLineCapStyle(caps[cap])
  gfx.drawLine(x1, y1, x2, y2); gfx.popContext()
  local t = {}
  for y = 0, H - 1 do for x = 0, W - 1 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = table.concat({ w, x1, y1, x2, y2, cap }, " ") .. "|" .. table.concat(t)
end
local fh = playdate.file.open("wide.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
