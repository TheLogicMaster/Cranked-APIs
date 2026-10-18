-- Probe: setPattern(image, x, y) on a 16x16 source (block or phase?), masked patterns over black and over a
-- clear destination, and short tables.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(16, 16)
local src = gfx.image.new(16, 16, gfx.kColorWhite)
math.randomseed(7)
gfx.pushContext(src); gfx.setColor(gfx.kColorBlack)
for y = 0, 15 do for x = 0, 15 do if math.random() < 0.4 then gfx.drawPixel(x, y) end end end
gfx.popContext()
local srcbits = {}
for y = 0, 15 do for x = 0, 15 do srcbits[#srcbits + 1] = src:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
out[#out + 1] = "src|" .. table.concat(srcbits)
local function dump(name)
  local t = {}
  for y = 0, 15 do for x = 0, 15 do local s = img:sample(x, y); t[#t + 1] = s == gfx.kColorBlack and "1" or (s == gfx.kColorWhite and "0" or "c") end end
  out[#out + 1] = name .. "|" .. table.concat(t)
end
local function case(name, bg, fn) img:clear(bg); gfx.pushContext(img); fn(); gfx.fillRect(0, 0, 16, 16); gfx.popContext(); dump(name) end
for _, xy in ipairs({{0,0},{1,0},{0,1},{3,2},{8,8},{5,7},{1,8},{8,0}}) do
  case("img16_" .. xy[1] .. "_" .. xy[2], gfx.kColorWhite, function() gfx.setPattern(src, xy[1], xy[2]) end)
end
local m = {0x13,0x05,0x0F,0xF0,0x81,0x42,0x24,0x18, 0xF0,0x0F,0xFF,0x3C,0xC3,0xAA,0x55,0xFF}
case("mask_white", gfx.kColorWhite, function() gfx.setPattern(m, 0, 0) end)
case("mask_black", gfx.kColorBlack, function() gfx.setPattern(m, 0, 0) end)
case("mask_clear", gfx.kColorClear, function() gfx.setPattern(m, 0, 0) end)
case("solid_clear", gfx.kColorClear, function() gfx.setPattern({0x13,0x05,0x0F,0xF0,0x81,0x42,0x24,0x18}, 0, 0) end)
case("short2_00", gfx.kColorBlack, function() gfx.setPattern({0x13, 0x05}, 0, 0) end)
case("short5_00", gfx.kColorBlack, function() gfx.setPattern({0x13, 0x05, 0x0F, 0xF0, 0x81}, 0, 0) end)
case("short9_00", gfx.kColorBlack, function() gfx.setPattern({0x13,0x05,0x0F,0xF0,0x81,0x42,0x24,0x18, 0x0F}, 0, 0) end)
case("short12_00", gfx.kColorBlack, function() gfx.setPattern({0x13,0x05,0x0F,0xF0,0x81,0x42,0x24,0x18, 0x0F,0xF0,0x3C,0xAA}, 0, 0) end)
case("empty_00", gfx.kColorBlack, function() gfx.setPattern({}, 0, 0) end)
local fh = playdate.file.open("pat7.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
