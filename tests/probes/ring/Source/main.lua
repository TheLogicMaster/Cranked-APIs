-- Probe: an orbit ring (white fill, then a wide dithered circle outline), and variants.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(64, 64)
local function dump(name)
  local t = {}
  for y = 0, 63 do for x = 0, 63 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = name .. "|" .. table.concat(t)
end
local function case(name, fn) img:clear(gfx.kColorWhite); gfx.pushContext(img); fn(); gfx.popContext(); dump(name) end
local function ring(alpha, w, prefill, mode)
  return function()
    if mode then gfx.setImageDrawMode(mode) end
    if prefill then gfx.setColor(gfx.kColorWhite); gfx.fillCircleAtPoint(32, 32, 20) end
    gfx.setColor(gfx.kColorBlack); gfx.setDitherPattern(alpha); gfx.setLineWidth(w); gfx.drawCircleAtPoint(32, 32, 20)
  end
end
case("ring_prefill", ring(0.75, 5, true, gfx.kDrawModeCopy))
case("noprefill", ring(0.75, 5, false))
case("w1", ring(0.75, 1, false))
case("a05", ring(0.5, 5, false))
case("a0", ring(0, 5, false))
case("solid_w5", function() gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(5); gfx.drawCircleAtPoint(32, 32, 20) end)
case("pat_w5", function() gfx.setPattern({0x55,0xAA,0x55,0xAA,0x55,0xAA,0x55,0xAA}); gfx.setLineWidth(5); gfx.drawCircleAtPoint(32, 32, 20) end)
case("fill_dither", function() gfx.setColor(gfx.kColorBlack); gfx.setDitherPattern(0.75); gfx.fillCircleAtPoint(32, 32, 20) end)
local fh = playdate.file.open("ring.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
