-- Probe: fillPolygon on random convex quadrilaterals (integer and fractional points), 40x40 target.
local gfx = playdate.graphics
local geo = playdate.geometry
local out = {}
local img = gfx.image.new(40, 40)
math.randomseed(21)
local function quad(frac)
  local cx, cy = 20, 20
  local angles = {}
  for i = 1, 4 do angles[i] = math.random() * 2 * math.pi end
  table.sort(angles)
  local pts = {}
  for i = 1, 4 do
    local r = 6 + math.random() * 12
    local x, y = cx + math.cos(angles[i]) * r, cy + math.sin(angles[i]) * r
    if not frac then x, y = math.floor(x + 0.5), math.floor(y + 0.5) end
    pts[#pts + 1] = x; pts[#pts + 1] = y
  end
  return pts
end
for i = 1, 60 do
  local frac = i > 30
  local p = quad(frac)
  img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack)
  local poly = geo.polygon.new(table.unpack(p)); poly:close(); gfx.fillPolygon(poly)
  gfx.popContext()
  local t = {}; for y = 0, 39 do for x = 0, 39 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  local ps = {}; for k = 1, #p do ps[k] = string.format("%.4f", p[k]) end
  out[#out + 1] = table.concat(ps, ",") .. "|" .. table.concat(t)
end
local fh = playdate.file.open("polyq.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
