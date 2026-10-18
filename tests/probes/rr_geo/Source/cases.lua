-- Probe: runs unchanged in the Simulator and in an emulator under test.
-- Objects are serialized through documented fields only, so userdata vs table does not matter.
local g = playdate.geometry
local R, P, V, L, A, Poly, S, T = g.rect, g.point, g.vector2D, g.lineSegment, g.arc, g.polygon, g.size, g.affineTransform

local function num(x)
    local s = string.format("%.4f", x)
    if s == "-0.0000" then s = "0.0000" end
    return s .. (math.type(x) == "integer" and "i" or "f")
end

local ser
local function kind(v)
    local mt = getmetatable(v)
    if mt == R then return "rect" elseif mt == P then return "point" elseif mt == V then return "vector"
    elseif mt == L then return "line" elseif mt == A then return "arc" elseif mt == Poly then return "poly"
    elseif mt == S then return "size" elseif mt == T then return "aff" end
    return nil
end

ser = function(v)
    local t = type(v)
    if t == "nil" then return "nil" end
    if t == "boolean" then return tostring(v) end
    if t == "number" then return num(v) end
    if t == "string" then return string.format("%q", v) end
    local k = kind(v)
    if k == "rect" then return "R(" .. num(v.x) .. "," .. num(v.y) .. "," .. num(v.width) .. "," .. num(v.height) .. ")" end
    if k == "point" then return "P(" .. num(v.x) .. "," .. num(v.y) .. ")" end
    if k == "vector" then return "V(" .. num(v.dx) .. "," .. num(v.dy) .. ")" end
    if k == "size" then return "S(" .. num(v.width) .. "," .. num(v.height) .. ")" end
    if k == "line" then return "L(" .. num(v.x1) .. "," .. num(v.y1) .. "," .. num(v.x2) .. "," .. num(v.y2) .. ")" end
    if k == "arc" then return "A(" .. num(v.x) .. "," .. num(v.y) .. "," .. num(v.radius) .. "," .. num(v.startAngle) .. "," .. num(v.endAngle) .. "," .. tostring(v:isClockwise()) .. ")" end
    if k == "aff" then return "T(" .. num(v.m11) .. "," .. num(v.m12) .. "," .. num(v.m21) .. "," .. num(v.m22) .. "," .. num(v.tx) .. "," .. num(v.ty) .. ")" end
    if k == "poly" then
        local parts = { "G(n=" .. tostring(v:count()) .. ",closed=" .. tostring(v:isClosed()) }
        for i = 1, v:count() do parts[#parts + 1] = ser(v:getPointAt(i)) end
        return table.concat(parts, ",") .. ")"
    end
    if t == "table" then
        local keys = {}
        for key in pairs(v) do keys[#keys + 1] = tostring(key) end
        table.sort(keys)
        local parts = {}
        for _, key in ipairs(keys) do parts[#parts + 1] = key .. "=" .. ser(v[tonumber(key) or key]) end
        return "{" .. table.concat(parts, ";") .. "}"
    end
    return t
end

local cases = {}
local function c(name, f) cases[#cases + 1] = { name, f } end
local function r(a, b, w, h) return R.new(a, b, w, h) end
local function sq() return Poly.new(0, 0, 10, 0, 10, 10, 0, 10, 0, 0) end
local function tri() return Poly.new(0, 0, 10, 0, 5, 10) end

-- rect
c("rect.new", function() return r(1, 2, 3, 4) end)
c("rect.new floats", function() return r(1.5, -2.5, 3.25, 4) end)
c("rect fields edges", function() local x = r(1, 2, 3, 4); return x.left, x.right, x.top, x.bottom end)
c("rect.size", function() return r(1, 2, 3, 4).size end)
c("rect.origin", function() return r(1, 2, 3, 4).origin end)
c("rect:copy", function() return r(1, 2, 3, 4):copy() end)
c("rect:toPolygon", function() return r(1, 2, 3, 4):toPolygon() end)
c("rect:unpack", function() return r(1, 2, 3, 4):unpack() end)
c("rect:isEmpty false", function() return r(1, 2, 3, 4):isEmpty() end)
c("rect:isEmpty zero w", function() return r(1, 2, 0, 4):isEmpty() end)
c("rect:isEmpty negative", function() return r(1, 2, -3, 4):isEmpty() end)
c("rect:isEqual", function() return r(1, 2, 3, 4):isEqual(r(1, 2, 3, 4)), r(1, 2, 3, 4):isEqual(r(1, 2, 3, 5)) end)
c("rect ==", function() return r(1, 2, 3, 4) == r(1, 2, 3, 4) end)
c("rect:intersects overlap", function() return r(0, 0, 10, 10):intersects(r(5, 5, 10, 10)) end)
c("rect:intersects touching", function() return r(0, 0, 10, 10):intersects(r(10, 0, 5, 5)) end)
c("rect:intersects apart", function() return r(0, 0, 10, 10):intersects(r(20, 20, 5, 5)) end)
c("rect:intersection", function() return r(0, 0, 10, 10):intersection(r(5, 5, 10, 10)) end)
c("rect:intersection none", function() return r(0, 0, 10, 10):intersection(r(20, 20, 5, 5)) end)
c("rect.fast_intersection", function() return R.fast_intersection(0, 0, 10, 10, 5, 5, 10, 10) end)
c("rect.fast_intersection none", function() return R.fast_intersection(0, 0, 10, 10, 20, 20, 5, 5) end)
c("rect:union", function() return r(0, 0, 10, 10):union(r(5, 5, 10, 10)) end)
c("rect.fast_union", function() return R.fast_union(0, 0, 10, 10, 5, 5, 10, 10) end)
c("rect:inset", function() local x = r(0, 0, 10, 10); x:inset(2, 3); return x end)
c("rect:insetBy", function() local x = r(0, 0, 10, 10); local y = x:insetBy(2, 3); return x, y end)
c("rect:inset negative", function() local x = r(0, 0, 10, 10); x:inset(-2, -3); return x end)
c("rect:offset", function() local x = r(0, 0, 10, 10); x:offset(2, 3); return x end)
c("rect:offsetBy", function() local x = r(0, 0, 10, 10); local y = x:offsetBy(2, 3); return x, y end)
c("rect:containsRect inside", function() return r(0, 0, 10, 10):containsRect(r(2, 2, 3, 3)) end)
c("rect:containsRect equal", function() return r(0, 0, 10, 10):containsRect(r(0, 0, 10, 10)) end)
c("rect:containsRect partial", function() return r(0, 0, 10, 10):containsRect(r(5, 5, 10, 10)) end)
c("rect:containsRect 4 numbers", function() return r(0, 0, 10, 10):containsRect(2, 2, 3, 3) end)
c("rect:containsPoint inside", function() return r(0, 0, 10, 10):containsPoint(P.new(5, 5)) end)
c("rect:containsPoint xy", function() return r(0, 0, 10, 10):containsPoint(5, 5) end)
c("rect:containsPoint edge left", function() return r(0, 0, 10, 10):containsPoint(0, 5) end)
c("rect:containsPoint edge right", function() return r(0, 0, 10, 10):containsPoint(10, 5) end)
c("rect:containsPoint outside", function() return r(0, 0, 10, 10):containsPoint(11, 5) end)
c("rect:centerPoint", function() return r(0, 0, 10, 20):centerPoint() end)
c("rect:flipRelativeToRect X", function() local x = r(1, 2, 3, 4); x:flipRelativeToRect(r(0, 0, 10, 10), g.kFlippedX); return x end)
c("rect:flipRelativeToRect Y", function() local x = r(1, 2, 3, 4); x:flipRelativeToRect(r(0, 0, 10, 10), g.kFlippedY); return x end)
c("rect:flipRelativeToRect XY", function() local x = r(1, 2, 3, 4); x:flipRelativeToRect(r(0, 0, 10, 10), g.kFlippedXY); return x end)
c("rect tostring", function() return tostring(r(1, 2, 3, 4)) end)
c("flip constants", function() return g.kUnflipped, g.kFlippedX, g.kFlippedY, g.kFlippedXY end)

-- point
c("point.new", function() return P.new(1, 2) end)
c("point:copy", function() return P.new(1, 2):copy() end)
c("point:unpack", function() return P.new(1, 2):unpack() end)
c("point:offset", function() local p = P.new(1, 2); p:offset(3, 4); return p end)
c("point:offsetBy", function() local p = P.new(1, 2); local q = p:offsetBy(3, 4); return p, q end)
c("point:squaredDistanceToPoint", function() return P.new(0, 0):squaredDistanceToPoint(P.new(3, 4)) end)
c("point:distanceToPoint", function() return P.new(0, 0):distanceToPoint(P.new(3, 4)) end)
c("point + vector", function() return P.new(1, 2) + V.new(3, 4) end)
c("point - vector", function() return P.new(1, 2) - V.new(3, 4) end)
c("point - point", function() return P.new(5, 7) - P.new(1, 2) end)
c("point * transform", function() return P.new(1, 2) * T.new(2, 0, 0, 3, 10, 20) end)
c("point .. point", function() return P.new(1, 2) .. P.new(3, 4) end)
c("point ==", function() return P.new(1, 2) == P.new(1, 2), P.new(1, 2) == P.new(1, 3) end)
c("point tostring", function() return tostring(P.new(1, 2)) end)

-- vector2D
c("vector.new", function() return V.new(3, 4) end)
c("vector.newPolar 0", function() return V.newPolar(10, 0) end)
c("vector.newPolar 90", function() return V.newPolar(10, 90) end)
c("vector.newPolar 45", function() return V.newPolar(10, 45) end)
c("vector x y aliases", function() local v = V.new(3, 4); return v.x, v.y end)
c("vector:copy", function() return V.new(3, 4):copy() end)
c("vector:unpack", function() return V.new(3, 4):unpack() end)
c("vector:addVector", function() local v = V.new(1, 2); v:addVector(V.new(3, 4)); return v end)
c("vector:scale", function() local v = V.new(1, 2); v:scale(3); return v end)
c("vector:scaledBy", function() local v = V.new(1, 2); local w = v:scaledBy(3); return v, w end)
c("vector:normalize", function() local v = V.new(3, 4); v:normalize(); return v end)
c("vector:normalized", function() local v = V.new(3, 4); local w = v:normalized(); return v, w end)
c("vector:normalize zero", function() local v = V.new(0, 0); v:normalize(); return v end)
c("vector:dotProduct", function() return V.new(1, 2):dotProduct(V.new(3, 4)) end)
c("vector:magnitude", function() return V.new(3, 4):magnitude() end)
c("vector:magnitudeSquared", function() return V.new(3, 4):magnitudeSquared() end)
c("vector:projectAlong", function() local v = V.new(3, 4); v:projectAlong(V.new(1, 0)); return v end)
c("vector:projectedAlong", function() return V.new(3, 4):projectedAlong(V.new(2, 0)) end)
c("vector:angleBetween 90", function() return V.new(1, 0):angleBetween(V.new(0, 1)) end)
c("vector:angleBetween -90", function() return V.new(0, 1):angleBetween(V.new(1, 0)) end)
c("vector:angleBetween 180", function() return V.new(1, 0):angleBetween(V.new(-1, 0)) end)
c("vector:leftNormal", function() return V.new(3, 4):leftNormal() end)
c("vector:rightNormal", function() return V.new(3, 4):rightNormal() end)
c("vector unary minus", function() return -V.new(3, 4) end)
c("vector + vector", function() return V.new(1, 2) + V.new(3, 4) end)
c("vector - vector", function() return V.new(1, 2) - V.new(3, 4) end)
c("vector * number", function() return V.new(1, 2) * 3 end)
c("vector * vector (dot)", function() return V.new(1, 2) * V.new(3, 4) end)
c("vector * transform", function() return V.new(1, 2) * T.new(2, 0, 0, 3, 10, 20) end)
c("vector / number", function() return V.new(3, 6) / 3 end)
c("vector ==", function() return V.new(1, 2) == V.new(1, 2) end)
c("vector tostring", function() return tostring(V.new(1, 2)) end)

-- size
c("size.new", function() return S.new(3, 4) end)
c("size:copy", function() return S.new(3, 4):copy() end)
c("size:unpack", function() return S.new(3, 4):unpack() end)

-- free functions
c("distanceToPoint", function() return g.distanceToPoint(0, 0, 3, 4) end)
c("squaredDistanceToPoint", function() return g.squaredDistanceToPoint(0, 0, 3, 4) end)

-- lineSegment
c("line.new", function() return L.new(0, 0, 10, 0) end)
c("line:copy", function() return L.new(0, 0, 10, 0):copy() end)
c("line:unpack", function() return L.new(1, 2, 3, 4):unpack() end)
c("line:length", function() return L.new(0, 0, 3, 4):length() end)
c("line:offset", function() local l = L.new(0, 0, 10, 0); l:offset(1, 2); return l end)
c("line:offsetBy", function() local l = L.new(0, 0, 10, 0); local m = l:offsetBy(1, 2); return l, m end)
c("line:midPoint", function() return L.new(0, 0, 10, 4):midPoint() end)
c("line:pointOnLine", function() return L.new(0, 0, 10, 0):pointOnLine(4) end)
c("line:pointOnLine past end", function() return L.new(0, 0, 10, 0):pointOnLine(14) end)
c("line:pointOnLine extend", function() return L.new(0, 0, 10, 0):pointOnLine(14, true) end)
c("line:pointOnLine negative", function() return L.new(0, 0, 10, 0):pointOnLine(-4) end)
c("line:segmentVector", function() return L.new(1, 2, 4, 6):segmentVector() end)
c("line:closestPointOnLineToPoint mid", function() return L.new(0, 0, 10, 0):closestPointOnLineToPoint(P.new(4, 5)) end)
c("line:closestPointOnLineToPoint beyond", function() return L.new(0, 0, 10, 0):closestPointOnLineToPoint(P.new(14, 5)) end)
c("line:intersectsLineSegment cross", function() return L.new(0, 0, 10, 10):intersectsLineSegment(L.new(0, 10, 10, 0)) end)
c("line:intersectsLineSegment apart", function() return L.new(0, 0, 1, 1):intersectsLineSegment(L.new(5, 0, 6, 0)) end)
c("line:intersectsLineSegment parallel", function() return L.new(0, 0, 10, 0):intersectsLineSegment(L.new(0, 1, 10, 1)) end)
c("line.fast_intersection cross", function() return L.fast_intersection(0, 0, 10, 10, 0, 10, 10, 0) end)
c("line.fast_intersection apart", function() return L.fast_intersection(0, 0, 1, 1, 5, 0, 6, 0) end)
c("line:intersectsPolygon", function() return L.new(-5, 5, 15, 5):intersectsPolygon(sq()) end)
c("line:intersectsPolygon none", function() return L.new(-5, 50, 15, 50):intersectsPolygon(sq()) end)
c("line:intersectsRect", function() return L.new(-5, 5, 15, 5):intersectsRect(r(0, 0, 10, 10)) end)
c("line:intersectsRect inside", function() return L.new(2, 2, 8, 8):intersectsRect(r(0, 0, 10, 10)) end)
c("line:intersectsRect none", function() return L.new(-5, 50, 15, 50):intersectsRect(r(0, 0, 10, 10)) end)
c("line * transform", function() return L.new(0, 0, 1, 1) * T.new(2, 0, 0, 3, 10, 20) end)

-- arc
c("arc.new", function() return A.new(0, 0, 10, 0, 90) end)
c("arc.new reversed angles", function() return A.new(0, 0, 10, 90, 0) end)
c("arc.new direction false", function() return A.new(0, 0, 10, 0, 90, false) end)
c("arc:copy", function() return A.new(0, 0, 10, 0, 90):copy() end)
c("arc:length", function() return A.new(0, 0, 10, 0, 90):length() end)
c("arc:length reversed", function() return A.new(0, 0, 10, 90, 0):length() end)
c("arc:setIsClockwise", function() local a = A.new(0, 0, 10, 0, 90); a:setIsClockwise(false); return a end)
c("arc:pointOnArc 0", function() return A.new(0, 0, 10, 0, 90):pointOnArc(0) end)
c("arc:pointOnArc quarter", function() return A.new(0, 0, 10, 0, 90):pointOnArc(math.pi * 10 / 4) end)
c("arc:pointOnArc past end", function() return A.new(0, 0, 10, 0, 90):pointOnArc(100) end)
c("arc:pointOnArc extend", function() return A.new(0, 0, 10, 0, 90):pointOnArc(100, true) end)

-- polygon
c("poly.new numbers", function() return tri() end)
c("poly.new points", function() return Poly.new(P.new(0, 0), P.new(10, 0), P.new(5, 10)) end)
c("poly.new count", function() return Poly.new(3) end)
c("poly closed by repeat", function() return sq() end)
c("poly:close", function() local p = tri(); p:close(); return p end)
c("poly:isClosed", function() return tri():isClosed(), sq():isClosed() end)
c("poly:count", function() return tri():count(), sq():count() end)
c("poly:copy", function() return tri():copy() end)
c("poly:getPointAt", function() return tri():getPointAt(2) end)
c("poly:setPointAt", function() local p = tri(); p:setPointAt(2, 20, 0); return p end)
c("poly:getBounds", function() return Poly.new(2, 3, 12, 3, 7, 13):getBounds() end)
c("poly:getBoundsRect", function() return Poly.new(2, 3, 12, 3, 7, 13):getBoundsRect() end)
c("poly:getBounds negative", function() return Poly.new(-5, -5, -1, -5, -3, -1):getBounds() end)
c("poly:length open", function() return tri():length() end)
c("poly:length closed", function() local p = tri(); p:close(); return p:length() end)
c("poly:pointOnPolygon", function() return sq():pointOnPolygon(15) end)
c("poly:pointOnPolygon past end", function() return tri():pointOnPolygon(100) end)
c("poly:pointOnPolygon extend", function() return tri():pointOnPolygon(100, true) end)
c("poly:translate", function() local p = tri(); p:translate(1, 2); return p end)
c("poly:containsPoint inside", function() return sq():containsPoint(P.new(5, 5)) end)
c("poly:containsPoint xy", function() return sq():containsPoint(5, 5) end)
c("poly:containsPoint outside", function() return sq():containsPoint(15, 5) end)
c("poly:containsPoint open", function() return tri():containsPoint(5, 2) end)
c("poly:intersects", function() return sq():intersects(Poly.new(5, 5, 15, 5, 15, 15, 5, 15, 5, 5)) end)
c("poly:intersects none", function() return sq():intersects(Poly.new(50, 50, 60, 50, 55, 60)) end)
c("poly * transform", function() return tri() * T.new(2, 0, 0, 3, 10, 20) end)
c("poly ==", function() return tri() == tri() end)

-- affineTransform
c("aff.new identity", function() return T.new() end)
c("aff.new values", function() return T.new(1, 2, 3, 4, 5, 6) end)
c("aff:copy", function() return T.new(1, 2, 3, 4, 5, 6):copy() end)
c("aff:invert", function() local t = T.new(2, 0, 0, 4, 10, 20); t:invert(); return t end)
c("aff:reset", function() local t = T.new(1, 2, 3, 4, 5, 6); t:reset(); return t end)
c("aff:concat", function() local t = T.new(2, 0, 0, 2, 0, 0); t:concat(T.new(1, 0, 0, 1, 5, 6)); return t end)
c("aff * aff", function() return T.new(2, 0, 0, 2, 0, 0) * T.new(1, 0, 0, 1, 5, 6) end)
c("aff:translate", function() local t = T.new(); t:translate(5, 6); return t end)
c("aff:translatedBy", function() local t = T.new(); local u = t:translatedBy(5, 6); return t, u end)
c("aff:scale one arg", function() local t = T.new(); t:scale(2); return t end)
c("aff:scale two args", function() local t = T.new(); t:scale(2, 3); return t end)
c("aff:scaledBy", function() local t = T.new(); local u = t:scaledBy(2, 3); return t, u end)
c("aff:rotate 90", function() local t = T.new(); t:rotate(90); return t end)
c("aff:rotate about xy", function() local t = T.new(); t:rotate(90, 5, 5); return t end)
c("aff:rotate about point", function() local t = T.new(); t:rotate(90, P.new(5, 5)); return t end)
c("aff:rotatedBy", function() local t = T.new(); local u = t:rotatedBy(90); return t, u end)
c("aff:skew", function() local t = T.new(); t:skew(1, 0); return t end)
c("aff:skewedBy", function() local t = T.new(); local u = t:skewedBy(0, 1); return t, u end)
c("aff order translate then scale", function() local t = T.new(); t:translate(5, 0); t:scale(2); return t end)
c("aff order scale then translate", function() local t = T.new(); t:scale(2); t:translate(5, 0); return t end)
c("aff:transformXY", function() return T.new(2, 0, 0, 3, 10, 20):transformXY(1, 2) end)
c("aff:transformPoint", function() local p = P.new(1, 2); T.new(2, 0, 0, 3, 10, 20):transformPoint(p); return p end)
c("aff:transformedPoint", function() local p = P.new(1, 2); local q = T.new(2, 0, 0, 3, 10, 20):transformedPoint(p); return p, q end)
c("aff:transformLineSegment", function() local l = L.new(0, 0, 1, 1); T.new(2, 0, 0, 3, 10, 20):transformLineSegment(l); return l end)
c("aff:transformedLineSegment", function() return T.new(2, 0, 0, 3, 10, 20):transformedLineSegment(L.new(0, 0, 1, 1)) end)
c("aff:transformAABB", function() local x = r(0, 0, 10, 10); T.new():rotatedBy(45):transformAABB(x); return x end)
c("aff:transformedAABB", function() return T.new():rotatedBy(45):transformedAABB(r(0, 0, 10, 10)) end)
c("aff:transformPolygon", function() local p = tri(); T.new(2, 0, 0, 3, 10, 20):transformPolygon(p); return p end)
c("aff:transformedPolygon", function() return T.new(2, 0, 0, 3, 10, 20):transformedPolygon(tri()) end)
c("aff tostring", function() return tostring(T.new()) end)

function runCases(write)
    for _, case in ipairs(cases) do
        local packed = table.pack(pcall(case[2]))
        local line
        if not packed[1] then
            line = "ERR"
        else
            local parts = {}
            for i = 2, packed.n do parts[#parts + 1] = ser(packed[i]) end
            line = table.concat(parts, " | ")
        end
        write(case[1] .. "\t" .. line)
    end
end
