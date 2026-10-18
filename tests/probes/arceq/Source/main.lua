-- Probe: equality of geometry objects with equal fields
local geo = playdate.geometry
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function t(name, a, b) local ok, r = pcall(function() return a == b end) fh:write(name .. " " .. tostring(ok) .. " " .. tostring(r) .. "\n") end
t("arc same", geo.arc.new(1, 2, 3, 4, 5), geo.arc.new(1, 2, 3, 4, 5))
t("arc diff", geo.arc.new(1, 2, 3, 4, 5), geo.arc.new(1, 2, 3, 4, 6))
t("arc dir", geo.arc.new(1, 2, 3, 4, 5, true), geo.arc.new(1, 2, 3, 4, 5, false))
t("point same", geo.point.new(1, 2), geo.point.new(1, 2))
t("rect same", geo.rect.new(1, 2, 3, 4), geo.rect.new(1, 2, 3, 4))
t("size same", geo.size.new(1, 2), geo.size.new(1, 2))
t("vector same", geo.vector2D.new(1, 2), geo.vector2D.new(1, 2))
t("line same", geo.lineSegment.new(1, 2, 3, 4), geo.lineSegment.new(1, 2, 3, 4))
t("transform same", geo.affineTransform.new(), geo.affineTransform.new())
t("polygon same", geo.polygon.new(1, 2, 3, 4, 5, 6), geo.polygon.new(1, 2, 3, 4, 5, 6))
t("arc vs table", geo.arc.new(1, 2, 3, 4, 5), {})
fh:close()
function playdate.update() end
