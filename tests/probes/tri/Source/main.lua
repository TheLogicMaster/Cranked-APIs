-- Probe: random filled triangles, including flat and degenerate ones.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(40, 40)
math.randomseed(31337)
for i = 1, 150 do
  local p = {}
  for k = 1, 6 do p[k] = math.random(2, 37) end
  if i % 10 == 0 then p[4] = p[2] end          -- flat edges
  if i % 15 == 0 then p[5], p[6] = p[1], p[2] end -- repeated vertex
  img:clear(gfx.kColorWhite)
  gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); gfx.fillTriangle(table.unpack(p)); gfx.popContext()
  local t = {}
  for y = 0, 39 do for x = 0, 39 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = table.concat(p, " ") .. "|" .. table.concat(t)
end
local fh = playdate.file.open("tri.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
