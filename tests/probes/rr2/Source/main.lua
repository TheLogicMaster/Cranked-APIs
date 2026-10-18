-- Probe: round rects over radii 0..20, line widths 0..9, stroke locations, sizes 1..44, random positions.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(56, 56)
local function case(name, fn)
  img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); fn(); gfx.popContext()
  local t = {}; for y = 0, 55 do for x = 0, 55 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = name .. "|" .. table.concat(t)
end
math.randomseed(4242)
local strokes = { gfx.kStrokeCentered, gfx.kStrokeInside, gfx.kStrokeOutside }
for i = 1, 150 do
  local x, y, w, h = math.random(2, 12), math.random(2, 12), math.random(1, 40), math.random(1, 40)
  local r = i <= 30 and (i - 1) % 6 or math.random(0, 20)
  local lw, sk = math.random(0, 9), math.random(1, 3)
  if i % 5 == 0 then w = -w end
  case(string.format("F %d %d %d %d %d", x, y, w, h, r), function() gfx.fillRoundRect(x + (w < 0 and 40 or 0), y, w, h, r) end)
  case(string.format("D %d %d %d %d %d %d %d", x, y, w, h, r, lw, sk), function()
    gfx.setLineWidth(lw); gfx.setStrokeLocation(strokes[sk]); gfx.drawRoundRect(x + (w < 0 and 40 or 0), y, w, h, r) end)
end
local fh = playdate.file.open("rr2.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
