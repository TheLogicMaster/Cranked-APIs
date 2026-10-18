-- Probe: setPattern argument edge cases (image with x only, image with x and y, eight integers, short tables).
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(16, 16)
local src = gfx.image.new(8, 8, gfx.kColorWhite)
gfx.pushContext(src); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 3, 2); gfx.drawPixel(6, 5); gfx.popContext()
local function dump(name)
  local t = {}
  for y = 0, 15 do for x = 0, 15 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or (img:sample(x, y) == gfx.kColorWhite and "0" or "c") end end
  out[#out + 1] = name .. "|" .. table.concat(t)
end
local function case(name, fn) img:clear(gfx.kColorWhite); gfx.pushContext(img); fn(); gfx.fillRect(0, 0, 16, 16); gfx.popContext(); dump(name) end
case("img_none", function() gfx.setPattern(src) end)
for _, x in ipairs({1, 3, 5}) do case("img_x" .. x, function() gfx.setPattern(src, x) end) end
for _, xy in ipairs({{1,2},{3,0},{0,5},{7,7}}) do case("img_xy" .. xy[1] .. xy[2], function() gfx.setPattern(src, xy[1], xy[2]) end) end
case("ints8", function() gfx.setPattern(0x13, 0x55, 0x0F, 0xF0, 0x81, 0x42, 0x24, 0x18) end)
case("ints8_b", function() gfx.setPattern(0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80) end)
case("short3", function() gfx.setPattern({0x13, 0x05}) end)
case("short1", function() gfx.setPattern({0x31}) end)
case("short1_x", function() gfx.setPattern({0x31}, 2) end)
case("mask16", function() gfx.setPattern({0x13,0x05,0x0F,0xF0,0x81,0x42,0x24,0x18, 0xF0,0x0F,0xFF,0x3C,0xC3,0xAA,0x55,0xFF}) end)
case("mask16_xy", function() gfx.setPattern({0x13,0x05,0x0F,0xF0,0x81,0x42,0x24,0x18, 0xF0,0x0F,0xFF,0x3C,0xC3,0xAA,0x55,0xFF}, 2, 3) end)
case("neg_xy", function() gfx.setPattern({0x13,0x05,0x0F,0xF0,0x81,0x42,0x24,0x18}, -3, -9) end)
case("frac_x", function() gfx.setPattern({0x13,0x05,0x0F,0xF0,0x81,0x42,0x24,0x18}, 2.0, 1) end)
local fh = playdate.file.open("pat6.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
