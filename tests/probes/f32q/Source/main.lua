-- Probe: are geometry fields single precision? (values read back, sums, and transform results)
local geom = playdate.geometry
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function w(label, v) fh:write(label .. " " .. string.format("%.17g", v) .. " " .. tostring(v) .. "\n") end
local p = geom.point.new(0.1, 1/3) w("point.x", p.x) w("point.y", p.y)
p.x = 0.7 w("point.x set", p.x)
local r = geom.rect.new(0.1, 0.2, 0.3, 0.4) w("rect.x", r.x) w("rect.width", r.width) w("rect:right", r.x + r.width)
local mx, my = r:centerPoint():unpack() w("rect center", mx)
local v = geom.vector2D.new(0.1, 0.2) w("vec.dx", v.dx) w("vec:magnitude", v:magnitude())
local s = geom.size.new(1/3, 0.1) w("size.width", s.width)
local l = geom.lineSegment.new(0.1, 0.2, 0.3, 0.4) w("line.x1", l.x1) w("line:length", l:length())
local a = geom.affineTransform.new() a:rotate(30) w("af.m11", a.m11) w("af.m12", a.m12)
a:translate(0.1, 0.2) w("af.tx", a.tx)
local q = a:transformedPoint(geom.point.new(10, 20)) w("af pt.x", q.x) w("af pt.y", q.y)
local b = geom.affineTransform.new(0.1, 0.2, 0.3, 0.4, 0.5, 0.6) w("af.new m11", b.m11)
local c = a * b w("a*b m11", c.m11) w("a*b tx", c.tx)
a:scale(1/3) w("af scaled m11", a.m11)
local arc = geom.arc.new(0.1, 0.2, 0.3, 10.5, 20.25) w("arc.x", arc.x) w("arc.radius", arc.radius)
local poly = geom.polygon.new(0.1, 0.2, 1.3, 1.4, 2.7, 0.1) local pp = poly:getPointAt(1) w("poly pt", pp.x) w("poly length", poly:length())
w("point dist", geom.point.new(0.1, 0.1):distanceToPoint(geom.point.new(1.2, 3.4)))
for i = 1, 30 do
  local ang = i * 13.7 - 100
  local t = geom.affineTransform.new() t:rotate(ang) w("rot " .. ang .. " m11", t.m11) w("rot m12", t.m12)
  local t2 = geom.affineTransform.new(1, 0.5, 0.25, 1, 3, 4) t2:rotate(ang, 10.5, -3) w("rotpt tx", t2.tx) w("rotpt m21", t2.m21)
  local t3 = geom.affineTransform.new() t3:skew(ang / 3, ang / 7) w("skew m12", t3.m12) w("skew m21", t3.m21)
  local v = geom.vector2D.newPolar(7.3, ang) w("polar dx", v.dx) w("polar dy", v.dy)
  local a = geom.vector2D.new(math.cos(i), math.sin(i * 2)) local b = geom.vector2D.new(-i, 3) w("angleBetween", a:angleBetween(b))
  local tl = t:transformedLineSegment(geom.lineSegment.new(0, 0, 500, 0)) w("tls x2", tl.x2) w("tls y2", tl.y2)
end
fh:close()
function playdate.update() end
