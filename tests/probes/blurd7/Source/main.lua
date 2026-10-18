-- Probe: blurredImage and drawBlurred over random images (with and without masks, trimmed), radii 0 to 6,
-- 1 to 3 passes, every dither type, phases, padding, and drawBlurred at clipped positions with flips
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local seed = 1
local function rnd(n) seed = (seed * 16807) % 2147483647 return seed % n end
local function rows(img)
  local w, h = img:getSize() local t = {}
  for y = 0, h - 1 do local r = {} for x = 0, w - 1 do local c = img:sample(x, y) r[#r + 1] = c == gfx.kColorBlack and "#" or (c == gfx.kColorWhite and "." or " ") end t[#t + 1] = table.concat(r) end
  return w .. "x" .. h .. ":" .. table.concat(t, "/")
end
local function randImage(mask)
  local w, h = 3 + rnd(18), 3 + rnd(14)
  local img = gfx.image.new(w, h, mask and gfx.kColorClear or gfx.kColorWhite)
  gfx.pushContext(img)
  for y = 0, h - 1 do for x = 0, w - 1 do
    local r = rnd(10)
    if r < 4 then gfx.setColor(gfx.kColorBlack) gfx.drawPixel(x, y) elseif r < 8 or not mask then gfx.setColor(gfx.kColorWhite) gfx.drawPixel(x, y) end
  end end
  gfx.popContext()
  return img
end
local trim = gfx.image.new("trim")
for i = 1, 80 do
  local img = (i % 7 == 0) and trim or randImage(i % 2 == 0)
  local r, passes, t = rnd(7), 1 + rnd(3), rnd(11)
  local pad = rnd(2) == 1
  local px, py = rnd(9) - 4, rnd(9) - 4
  local ok, res
  if i % 3 == 0 then ok, res = pcall(img.blurredImage, img, r, passes, t, pad) else ok, res = pcall(img.blurredImage, img, r, passes, t, pad, px, py) end
  if false then fh:write(string.format("B %d r=%d p=%d t=%d pad=%s ph=%d,%d %s %s\n", i, r, passes, t, tostring(pad), px, py, tostring(ok), ok and rows(res) or tostring(res))) end
end
for i = 1, 40 do
  local img = (i % 5 == 0) and trim or randImage(i % 2 == 0)
  local r, passes, t = rnd(6), 1 + rnd(2), rnd(11)
  local x, y = rnd(40) - 12, rnd(30) - 10
  local canvas = gfx.image.new(40, 30, gfx.kColorClear)
  gfx.pushContext(canvas)
  if i % 4 == 0 then gfx.setClipRect(5, 4, 25, 18) end
  if i % 6 == 0 then gfx.setDrawOffset(3, -2) end
  local ok, e
  if i % 3 == 0 then ok, e = pcall(img.drawBlurred, img, x, y, r, passes, t, gfx.kImageFlippedX)
  elseif i % 3 == 1 then ok, e = pcall(img.drawBlurred, img, x, y, r, passes, t, rnd(5) - 2, rnd(5) - 2)
  else ok, e = pcall(img.drawBlurred, img, x, y, r, passes, t) end
  gfx.popContext()
  if i == 7 or i == 18 then fh:write(string.format("D %d x=%d y=%d r=%d p=%d t=%d %s %s %s\nIMG %s mask=%s\n", i, x, y, r, passes, t, tostring(ok), tostring(e), rows(canvas), rows(img), tostring(img:hasMask()))) end
end
fh:close()
function playdate.update() end
