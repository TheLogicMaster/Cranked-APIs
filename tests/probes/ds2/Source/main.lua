-- Probe: image:drawSampled with random centers, matrices, offsets, z, tilt and tiling.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
math.randomseed(5150)
local src = gfx.image.new(16, 12, gfx.kColorWhite)
gfx.pushContext(src); gfx.setColor(gfx.kColorBlack)
for k = 1, 60 do gfx.drawPixel(math.random(0, 15), math.random(0, 11)) end
gfx.fillRect(0, 0, 4, 4); gfx.drawLine(0, 11, 15, 0)
gfx.popContext()
local canvas = gfx.image.new(48, 32)
for i = 1, 100 do
  local w, h = math.random(8, 48), math.random(6, 32)
  local cx, cy = math.random(), math.random()
  local dxx, dyx, dxy, dyy = math.random() * 2 - 0.5, (i % 3 == 0) and (math.random() - 0.5) or 0, (i % 4 == 0) and (math.random() - 0.5) or 0, math.random() * 2 - 0.5
  local dx, dy = math.random() * 2 - 1, math.random() * 2 - 1
  local z = 4 + math.random() * 60
  local tilt = (i % 5 == 0) and 0 or (math.random() * 140 - 60)
  local tile = i % 2 == 0
  canvas:clear(gfx.kColorWhite); gfx.pushContext(canvas)
  src:drawSampled(0, 0, w, h, cx, cy, dxx, dyx, dxy, dyy, dx, dy, z, tilt, tile)
  gfx.popContext()
  local t = {}; for y = 0, 31 do for x = 0, 47 do t[#t + 1] = canvas:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = string.format("%d %d %d %.6g %.6g %.6g %.6g %.6g %.6g %.6g %.6g %.6g %.6g %s", i, w, h, cx, cy, dxx, dyx, dxy, dyy, dx, dy, z, tilt, tostring(tile)) .. "|" .. table.concat(t)
end
local fh = playdate.file.open("ds2.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
