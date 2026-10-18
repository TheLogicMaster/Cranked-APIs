-- Probe: drawFaded and fadedImage across every dither type, with clipping, offsets, flips and odd alphas
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function sig(t) local n, s = 0, 0 local W, H = t:getSize() for y = 0, H - 1 do for x = 0, W - 1 do local c = t:sample(x, y) if c == gfx.kColorBlack then n = n + 1 s = (s * 31 + x * 7 + y) % 1000003 elseif c == gfx.kColorClear then s = (s * 13 + x + y * 5) % 1000003 end end end return n .. ":" .. s end
local imgs = {}
imgs.u1 = gfx.image.new("u1")
local g = gfx.image.new(23, 17, gfx.kColorWhite)
gfx.pushContext(g) gfx.setColor(gfx.kColorBlack) gfx.fillCircleAtPoint(11, 8, 7) gfx.drawLine(0, 16, 22, 0) gfx.popContext()
imgs.solid = g
local m = gfx.image.new(19, 13, gfx.kColorClear)
gfx.pushContext(m) gfx.setColor(gfx.kColorBlack) gfx.fillRect(2, 1, 9, 10) gfx.setColor(gfx.kColorWhite) gfx.fillRect(9, 4, 9, 8) gfx.popContext()
imgs.masked = m
local names = { "u1", "solid", "masked" }
local alphas = { -0.3, 0.1, 0.3, 0.5, 0.66, 0.9, 1.4 }
local places = { { 3, 2 }, { -5, -4 }, { 50, 33 }, { 17, 9, "clip" }, { 8, 6, "off" }, { 6, 4, "flip" } }
for _, nm in ipairs(names) do
  local img = imgs[nm]
  for ty = 0, 10 do
    for _, a in ipairs(alphas) do
      local parts = {}
      for _, p in ipairs(places) do
        local t = gfx.image.new(60, 40, gfx.kColorWhite)
        gfx.pushContext(t)
        if p[3] == "clip" then gfx.setClipRect(20, 11, 13, 9) end
        if p[3] == "off" then gfx.setDrawOffset(-3, 5) end
        local ok, e
        if p[3] == "flip" then ok, e = pcall(img.drawFaded, img, p[1], p[2], a, ty, gfx.kImageFlippedXY)
        else ok, e = pcall(img.drawFaded, img, p[1], p[2], a, ty) end
        gfx.popContext()
        parts[#parts + 1] = ok and sig(t) or ("err " .. tostring(e))
      end
      local ok, f = pcall(img.fadedImage, img, a, ty)
      fh:write(string.format("%s t=%d a=%s draw=%s faded=%s\n", nm, ty, tostring(a), table.concat(parts, " "), ok and (f and sig(f) or "nil") or ("err " .. tostring(f))))
    end
  end
end
fh:close()
function playdate.update() end
