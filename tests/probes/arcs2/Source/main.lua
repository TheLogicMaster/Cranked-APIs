-- Probe: ellipse arcs and pies (fill and outline, widths 1, 2, 5), drawArc, and rounding of negative halves.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(40, 40)
local function case(name, fn)
  img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); fn(); gfx.popContext()
  local t = {}; for y = 0, 39 do for x = 0, 39 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = name .. "|" .. table.concat(t)
end
math.randomseed(7)
local sizes = { {30, 30}, {31, 25}, {34, 16}, {15, 33} }
for i = 1, 48 do
  local s = sizes[(i - 1) % 4 + 1]
  local a0, a1 = math.random(0, 359), math.random(0, 359)
  if i % 6 == 0 then a0 = a0 - 360 end
  if i % 7 == 0 then a1 = a1 + 0.5 end
  local lw = ({1, 2, 5})[(i - 1) // 16 + 1]
  case(string.format("f %d %d %g %g", s[1], s[2], a0, a1), function() gfx.fillEllipseInRect(4, 5, s[1], s[2], a0, a1) end)
  case(string.format("d %d %d %g %g w%d", s[1], s[2], a0, a1, lw), function() gfx.setLineWidth(lw); gfx.drawEllipseInRect(4, 5, s[1], s[2], a0, a1) end)
end
for _, q in ipairs({ {0, 90}, {90, 180}, {180, 270}, {270, 360}, {45, 135}, {300, 60}, {10, 350}, {0, 1}, {359, 0}, {90, 90.5} }) do
  case(string.format("f 30 30 %g %g", q[1], q[2]), function() gfx.fillEllipseInRect(4, 5, 30, 30, q[1], q[2]) end)
  case(string.format("d 30 30 %g %g w1", q[1], q[2]), function() gfx.setLineWidth(1); gfx.drawEllipseInRect(4, 5, 30, 30, q[1], q[2]) end)
end
for i = 1, 12 do
  local r, a0, a1, lw = 6 + math.random() * 10, math.random(0, 359), math.random(0, 359), (i % 3) + 1
  case(string.format("arc %.3f %d %d w%d", r, a0, a1, lw), function() gfx.setLineWidth(lw); gfx.drawArc(20, 20, r, a0, a1) end)
end
for _, v in ipairs({ -0.5, -1.5, -2.5, -3.5, -0.7, -1.2 }) do
  case("negx " .. v, function() gfx.fillEllipseInRect(v, 4, 14, 14) end)
end
case("negw", function() gfx.fillEllipseInRect(20.5, 4, -12.5, 14) end)
case("lwarg", function() gfx.setLineWidth(1); gfx.drawEllipseInRect(4, 4, 30, 30, 4) end)
case("lwarg2", function() gfx.setLineWidth(1); gfx.drawEllipseInRect(4, 4, 30, 30, 0, 180, 4) end)
local fh = playdate.file.open("arcs2.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
