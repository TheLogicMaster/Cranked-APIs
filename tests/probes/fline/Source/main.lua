-- Probe: 1-pixel lines with fractional end points, drawn into 48x48 images.
import "CoreLibs/graphics"
local gfx = playdate.graphics
math.randomseed(777)
local out = {}
for i = 1, 60 do
  local x1, y1 = math.random(40, 400) / 10, math.random(40, 440) / 10
  local x2, y2 = math.random(40, 440) / 10, math.random(40, 440) / 10
  if i <= 30 then y2 = y1 + math.random(-60, 60) / 10 end -- mostly shallow
  local img = gfx.image.new(48, 48, gfx.kColorWhite)
  gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.drawLine(x1, y1, x2, y2); gfx.popContext()
  local rows = {}
  for y = 0, 47 do local t = {}; for x = 0, 47 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end; rows[#rows + 1] = table.concat(t) end
  out[#out + 1] = string.format("%g,%g,%g,%g", x1, y1, x2, y2) .. "\t" .. table.concat(rows, "/")
end
local fh = playdate.file.open("fline.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
