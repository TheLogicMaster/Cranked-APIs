-- Probe: rotatedImage and drawRotated on random images (with transparency) at random angles and scales.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
math.randomseed(1011)
local function dumpImg(im)
  local w, h = im:getSize(); local t = {}
  for y = 0, h - 1 do for x = 0, w - 1 do
    local c = im:sample(x, y); t[#t + 1] = c == gfx.kColorBlack and "0" or (c == gfx.kColorWhite and "1" or "x")
  end end
  return w .. "x" .. h .. ":" .. table.concat(t)
end
local function randImg()
  local w, h = math.random(2, 18), math.random(2, 18)
  local im = gfx.image.new(w, h, gfx.kColorClear)
  gfx.pushContext(im)
  for y = 0, h - 1 do for x = 0, w - 1 do
    local r = math.random(); if r < 0.45 then gfx.setColor(gfx.kColorBlack); gfx.drawPixel(x, y) elseif r < 0.85 then gfx.setColor(gfx.kColorWhite); gfx.drawPixel(x, y) end
  end end
  gfx.popContext()
  return im
end
for i = 1, 120 do
  local im = randImg()
  local a
  if i % 10 == 0 then a = math.random(-4, 4) * 90 elseif i % 10 == 5 then a = math.random(-8, 8) * 45 else a = math.random() * 800 - 400 end
  local sx, sy = 1, 1
  if i % 3 == 1 then sx = 0.4 + math.random() * 2; sy = sx end
  if i % 3 == 2 then sx = 0.4 + math.random() * 2; sy = 0.4 + math.random() * 2 end
  if i % 8 == 0 then sx = -sx end
  if i % 9 == 0 then sy = -sy end
  local r = im:rotatedImage(a, sx, sy)
  out[#out + 1] = string.format("R %d %.9g %.9g %.9g %s", i, a, sx, sy, dumpImg(im)) .. "|" .. dumpImg(r)
end
local canvas = gfx.image.new(64, 64)
for i = 1, 60 do
  local im = randImg()
  local a = (i % 6 == 0) and math.random(0, 3) * 90 or math.random() * 720 - 360
  local x, y = 20 + math.random() * 24, 20 + math.random() * 24
  if i % 2 == 0 then x, y = math.floor(x), math.floor(y) end
  local s = (i % 3 == 0) and (0.5 + math.random() * 1.5) or 1
  canvas:clear(gfx.kColorClear)
  gfx.pushContext(canvas); im:drawRotated(x, y, a, s); gfx.popContext()
  out[#out + 1] = string.format("D %d %.9g %.9g %.9g %.9g %s", i, a, x, y, s, dumpImg(im)) .. "|" .. dumpImg(canvas)
end
local fh = playdate.file.open("rot3.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
