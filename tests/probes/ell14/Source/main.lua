-- Probe: ellipses with a 14-pixel axis (fills and outlines), and circles 13..15 at several positions.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(40, 40)
local function case(name, fn)
  img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); fn(); gfx.popContext()
  local t = {}; for y = 0, 39 do for x = 0, 39 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = name .. "|" .. table.concat(t)
end
for _, wh in ipairs({ {14, 14}, {14, 20}, {20, 14}, {14, 8}, {8, 14}, {14, 30}, {30, 14}, {14, 13}, {13, 14}, {14, 15}, {15, 14}, {28, 28}, {7, 7} }) do
  case(string.format("fill %d %d", wh[1], wh[2]), function() gfx.fillEllipseInRect(3, 4, wh[1], wh[2]) end)
  for _, lw in ipairs({1, 2, 3}) do
    case(string.format("draw %d %d w%d", wh[1], wh[2], lw), function() gfx.setLineWidth(lw); gfx.drawEllipseInRect(5, 5, wh[1], wh[2]) end)
  end
end
for _, r in ipairs({6.5, 7, 7.4}) do
  case("fillcircle " .. r, function() gfx.fillCircleAtPoint(20, 20, r) end)
  case("drawcircle2 " .. r, function() gfx.setLineWidth(2); gfx.drawCircleAtPoint(20, 20, r) end)
end
local fh = playdate.file.open("ell14.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
