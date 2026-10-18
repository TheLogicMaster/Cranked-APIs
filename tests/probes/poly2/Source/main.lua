-- Probe: fillPolygon on random 4..10-vertex polygons (non-monotone, self-intersecting, stars, repeated and
-- collinear points), both fill rules, partly off the image, with a clip rect and a draw offset.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local geo = playdate.geometry
local out = {}
local img = gfx.image.new(48, 48)
math.randomseed(777)
for i = 1, 160 do
  local n = math.random(4, 10)
  local p = {}
  local star = i % 4 == 0
  for k = 1, n do
    local x, y
    if star then
      local a = (k - 1) * 2 * math.pi * 2 / n; local r = 6 + math.random() * 16
      x, y = 24 + math.cos(a) * r, 24 + math.sin(a) * r
    else
      x, y = math.random(-8, 55), math.random(-8, 55)
    end
    if i % 3 ~= 0 then x, y = math.floor(x + 0.5), math.floor(y + 0.5) end
    p[#p + 1] = x; p[#p + 1] = y
  end
  if i % 7 == 0 then p[#p + 1] = p[1]; p[#p + 1] = p[2] end           -- repeated closing point
  if i % 11 == 0 then p[5] = (p[1] + p[3]) / 2; p[6] = (p[2] + p[4]) / 2 end -- collinear-ish point
  local rule = (i % 2 == 0) and gfx.kPolygonFillEvenOdd or gfx.kPolygonFillNonZero
  local clip = i % 5 == 0; local off = i % 6 == 0
  do local fp = playdate.file.open("progress.txt", playdate.file.kFileWrite); fp:write(i .. " " .. table.concat(p, ",") .. "\n"); fp:close() end
  img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack)
  gfx.setPolygonFillRule(rule)
  if off then gfx.setDrawOffset(3, -4) end
  if clip then gfx.setClipRect(6, 9, 30, 28) end
  if i % 2 == 1 then gfx.fillPolygon(table.unpack(p)) else local q = geo.polygon.new(table.unpack(p)); q:close(); gfx.fillPolygon(q) end -- an open polygon object hangs the Simulator
  gfx.popContext()
  local t = {}; for y = 0, 47 do for x = 0, 47 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  local ps = {}; for k = 1, #p do ps[k] = string.format("%.3f", p[k]) end
  local pre = string.format("%d %s", i, table.concat(p, ","))
  local fp = playdate.file.open("progress.txt", playdate.file.kFileWrite); fp:write(pre .. "\n"); fp:close()
  out[#out + 1] = string.format("%d %d %s %s %s", i, rule, clip and "c" or "-", off and "o" or "-", table.concat(ps, ",")) .. "|" .. table.concat(t)
end
local fh = playdate.file.open("poly2.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
