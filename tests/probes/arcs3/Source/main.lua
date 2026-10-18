-- Probe: fresh random validation of ellipses, arcs and pies (sizes 1..44, widths 0..9, stroke locations,
-- fractional values, partly outside the image, clip rect, angle arguments outside 0..360).
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(48, 48)
local function case(name, fn)
  img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); fn(); gfx.popContext()
  local t = {}; for y = 0, 47 do for x = 0, 47 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = name .. "|" .. table.concat(t)
end
math.randomseed(20261011)
local strokes = { gfx.kStrokeCentered, gfx.kStrokeInside, gfx.kStrokeOutside }
for i = 1, 160 do
  local x, y = math.random(-6, 20) + (i % 3 == 0 and math.random() or 0), math.random(-6, 20) + (i % 5 == 0 and math.random() or 0)
  local w, h = math.random(1, 44), math.random(1, 44)
  if i % 4 == 0 then h = w end
  local full = i % 3 == 1
  local a0, a1 = math.random(-400, 760) / (i % 2 == 0 and 2 or 1), math.random(-400, 760) / (i % 2 == 0 and 1 or 2)
  local lw, sk = math.random(0, 9), math.random(1, 3)
  local clip = i % 9 == 0
  local name = string.format("%d %g %g %d %d %s %g %g %d %d %s", i, x, y, w, h, full and "full" or "arc", a0, a1, lw, sk, clip and "clip" or "")
  case("F " .. name, function()
    if clip then gfx.setClipRect(10, 8, 25, 30) end
    if full then gfx.fillEllipseInRect(x, y, w, h) else gfx.fillEllipseInRect(x, y, w, h, a0, a1) end
  end)
  case("D " .. name, function()
    if clip then gfx.setClipRect(10, 8, 25, 30) end
    gfx.setLineWidth(lw); gfx.setStrokeLocation(strokes[sk])
    if full then gfx.drawEllipseInRect(x, y, w, h) else gfx.drawEllipseInRect(x, y, w, h, a0, a1) end
  end)
end
for i = 1, 20 do
  local cx, cy, r, a0, a1, lw = 24 + math.random() * 3, 24 + math.random() * 3, 2 + math.random() * 18, math.random(0, 359), math.random(0, 359), math.random(1, 6)
  case(string.format("A %.4f %.4f %.4f %d %d %d", cx, cy, r, a0, a1, lw), function() gfx.setLineWidth(lw); gfx.drawArc(playdate.geometry.arc.new(cx, cy, r, a0, a1)) end)
  case(string.format("C %.4f %.4f %.4f %d", cx, cy, r, lw), function() gfx.setLineWidth(lw); gfx.drawCircleAtPoint(cx, cy, r) end)
  case(string.format("FC %.4f %.4f %.4f", cx, cy, r), function() gfx.fillCircleAtPoint(cx, cy, r) end)
end
local fh = playdate.file.open("arcs3.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
