-- Probe: drawLine with kColorXOR over black and white, various slopes; also XOR fillRect and drawRect.
local gfx = playdate.graphics
local out = {}
local function case(name, bg, fn)
  local d = gfx.image.new(24, 24, bg); gfx.pushContext(d); fn(); gfx.popContext()
  local t = {}; for y = 0, 23 do for x = 0, 23 do t[#t + 1] = d:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = name .. "|" .. table.concat(t)
end
local lines = { {2, 2, 20, 2}, {2, 2, 20, 5}, {2, 2, 20, 20}, {2, 2, 5, 20}, {2, 20, 20, 2}, {20, 2, 2, 9}, {3, 3, 3, 3}, {2, 2, 2, 20} }
for i, l in ipairs(lines) do
  for _, bg in ipairs({ gfx.kColorBlack, gfx.kColorWhite }) do
    for _, w in ipairs({1, 2, 3}) do
      case(string.format("line%d bg%d w%d", i, bg, w), bg, function() gfx.setColor(gfx.kColorXOR); gfx.setLineWidth(w); gfx.drawLine(l[1], l[2], l[3], l[4]) end)
    end
  end
end
case("fillRect xor", gfx.kColorBlack, function() gfx.setColor(gfx.kColorXOR); gfx.fillRect(2, 2, 10, 10) end)
case("drawRect xor", gfx.kColorBlack, function() gfx.setColor(gfx.kColorXOR); gfx.drawRect(2, 2, 10, 10) end)
case("drawRect xor w2", gfx.kColorBlack, function() gfx.setColor(gfx.kColorXOR); gfx.setLineWidth(2); gfx.drawRect(2, 2, 10, 10) end)
case("triangle xor", gfx.kColorBlack, function() gfx.setColor(gfx.kColorXOR); gfx.fillTriangle(2, 2, 20, 5, 8, 20) end)
case("circle xor", gfx.kColorBlack, function() gfx.setColor(gfx.kColorXOR); gfx.drawEllipseInRect(2, 2, 18, 14) end)
local fh = playdate.file.open("xorline.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
