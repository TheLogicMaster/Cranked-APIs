-- Probe: number types of geometry fields after construction with integers and after assigning integers
local geo = playdate.geometry
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local realWrite = fh.write
local function t(v) return math.type(v) .. ":" .. tostring(v) end
local objs = {
  { "rect", geo.rect.new(1, 2, 3, 4), { "x", "y", "width", "height", "w", "h" } },
  { "point", geo.point.new(1, 2), { "x", "y" } },
  { "size", geo.size.new(3, 4), { "width", "height", "w", "h" } },
  { "vector2D", geo.vector2D.new(1, 2), { "dx", "dy", "x", "y" } },
  { "lineSegment", geo.lineSegment.new(1, 2, 3, 4), { "x1", "y1", "x2", "y2" } },
  { "arc", geo.arc.new(1, 2, 3, 4, 5), { "x", "y", "radius", "startAngle", "endAngle" } },
  { "affineTransform", geo.affineTransform.new(1, 0, 0, 1, 2, 3), { "m11", "m12", "m21", "m22", "tx", "ty" } },
}
for _, o in ipairs(objs) do
  local parts = {}
  for _, k in ipairs(o[3]) do
    local ok, v = pcall(function() return o[2][k] end)
    parts[#parts + 1] = k .. "=" .. (ok and t(v) or "err")
  end
  fh:write(o[1] .. " new: " .. table.concat(parts, " ") .. "\n") fh:flush()
  parts = {}
  for _, k in ipairs(o[3]) do
    local ok, e = pcall(function() o[2][k] = 7 end)
    local ok2, v = pcall(function() return o[2][k] end)
    parts[#parts + 1] = k .. "=" .. (ok and (ok2 and t(v) or "err") or ("seterr " .. tostring(e)))
  end
  fh:write(o[1] .. " set 7: " .. table.concat(parts, " ") .. "\n") fh:flush()
end
local r = geo.rect.new(0, 0, 10, 10) r.x = 2^31 - 1 fh:write("big " .. t(r.x) .. "\n") fh:flush()
local p = geo.point.new(1, 1) local okp, ep = pcall(function() p.x = "5" end) fh:write("string " .. tostring(okp) .. " " .. tostring(ep) .. " " .. tostring(p.x) .. "\n") fh:flush()
local r2 = geo.rect.new(1, 1, 4, 4) local u = r2:unionWith(geo.rect.new(5, 5, 2, 2)) fh:write("union " .. t(u.x) .. " " .. t(u.width) .. "\n") fh:flush()
local c = r2:centerPoint() fh:write("center " .. t(c.x) .. "\n") fh:flush()
fh:close()
function playdate.update() end
