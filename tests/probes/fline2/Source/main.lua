-- Probe: every integer line from (13, 13) to (13 + dx, 13 + dy), |dx|, |dy| <= 12, both orders.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(27, 27)
for dy = -12, 12 do for dx = -12, 12 do for order = 0, 1 do
  img:clear(gfx.kColorWhite)
  gfx.pushContext(img); gfx.setColor(gfx.kColorBlack)
  if order == 0 then gfx.drawLine(13, 13, 13 + dx, 13 + dy) else gfx.drawLine(13 + dx, 13 + dy, 13, 13) end
  gfx.popContext()
  local p = {}
  for y = 0, 26 do for x = 0, 26 do if img:sample(x, y) == gfx.kColorBlack then p[#p + 1] = x .. "," .. y end end end
  out[#out + 1] = dx .. " " .. dy .. " " .. order .. "\t" .. table.concat(p, ";")
end end end
local fh = playdate.file.open("fline2.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
