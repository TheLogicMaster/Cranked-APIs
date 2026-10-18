-- Probe: drawScaled and scaledImage with fractional and negative scales, random images with transparency.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
math.randomseed(99)
local function dumpImg(im)
  local w, h = im:getSize(); local t = {}
  for y = 0, h - 1 do for x = 0, w - 1 do
    local c = im:sample(x, y); t[#t + 1] = c == gfx.kColorBlack and "0" or (c == gfx.kColorWhite and "1" or "x")
  end end
  return w .. "x" .. h .. ":" .. table.concat(t)
end
local function randImg()
  local w, h = math.random(1, 14), math.random(1, 14)
  local im = gfx.image.new(w, h, gfx.kColorClear)
  gfx.pushContext(im)
  for y = 0, h - 1 do for x = 0, w - 1 do
    local r = math.random(); if r < 0.45 then gfx.setColor(gfx.kColorBlack); gfx.drawPixel(x, y) elseif r < 0.85 then gfx.setColor(gfx.kColorWhite); gfx.drawPixel(x, y) end
  end end
  gfx.popContext()
  return im
end
local canvas = gfx.image.new(48, 48)
for i = 1, 80 do
  local im = randImg()
  local sx = (0.2 + math.random() * 3.3) * (i % 4 == 0 and -1 or 1)
  local sy = (i % 2 == 0) and sx or (0.2 + math.random() * 3.3) * (i % 5 == 0 and -1 or 1)
  local x, y = math.random(-4, 20), math.random(-4, 20)
  canvas:clear(gfx.kColorClear); gfx.pushContext(canvas); im:drawScaled(x, y, sx, sy); gfx.popContext()
  out[#out + 1] = string.format("D %d %.9g %.9g %d %d %s", i, sx, sy, x, y, dumpImg(im)) .. "|" .. dumpImg(canvas)
  out[#out + 1] = string.format("S %d %.9g %.9g %s", i, sx, sy, dumpImg(im)) .. "|" .. dumpImg(im:scaledImage(sx, sy))
end
local fh = playdate.file.open("sc2.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
