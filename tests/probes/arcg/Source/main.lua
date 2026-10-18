-- Probe: geometry.arc length, pointOnArc (with and without extend), and default direction.
local geom = playdate.geometry
local out = {}
local cases = { {45, 290, false}, {45, 290, true}, {290, 45, true}, {290, 45, false}, {0, 90, nil}, {90, 0, nil},
  {350, 10, true}, {350, 10, false}, {10, 350, nil}, {0, 360, true}, {0, 360, false}, {30, 30, true}, {30, 30, false},
  {-90, 90, true}, {-90, 90, false}, {400, 100, true}, {400, 100, false}, {0, 720, true}, {720, 0, false}, {100, -100, nil} }
for i, c in ipairs(cases) do
  local a = c[3] == nil and geom.arc.new(5, 6, 10, c[1], c[2]) or geom.arc.new(5, 6, 10, c[1], c[2], c[3])
  local L = a:length()
  local pts = {}
  for _, d in ipairs({0, 5, L * 0.5, L, L + 7, -4}) do
    local p = a:pointOnArc(d); local q = a:pointOnArc(d, true)
    pts[#pts + 1] = string.format("%.3f,%.3f/%.3f,%.3f", p.x, p.y, q.x, q.y)
  end
  out[#out + 1] = string.format("%d|%s %s %s cw=%s len=%.4f|%s", i, tostring(c[1]), tostring(c[2]), tostring(c[3]), tostring(a:isClockwise()), L, table.concat(pts, " "))
end
local fh = playdate.file.open("arcg.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
