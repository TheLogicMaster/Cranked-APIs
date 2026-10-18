-- Probe: wide rounded rects, random triangles and polygons, odd-sized and centered-stroke ellipses, drawSampled tilt, and the collision world after removeAll
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function dump(name, img)
    local w, h = img:getSize()
    local rows = {}
    for y = 0, h - 1 do
        local r = {}
        for x = 0, w - 1 do r[#r + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end
        rows[#rows + 1] = table.concat(r)
    end
    out:write(name .. "\t" .. table.concat(rows, "/") .. "\n")
end
local function case(name, w, h, f)
    local img = gfx.image.new(w, h, gfx.kColorWhite)
    gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); f(); gfx.popContext()
    dump(name, img)
end
math.randomseed(7)
for i = 1, 6 do case("wide rounded rect " .. i, 80, 60, function() gfx.setLineWidth(2 + i); gfx.drawRoundRect(5, 5, 60 + i, 40 + i, 4 + i * 2) end) end
for i = 1, 8 do
    local p = {}
    for k = 1, 6 do p[k] = math.random(0, 63) end
    case("triangle " .. i, 64, 64, function() gfx.fillTriangle(p[1], p[2], p[3], p[4], p[5], p[6]) end)
    case("polygon " .. i, 64, 64, function() gfx.fillPolygon(p[1], p[2], p[3], p[4], p[5], p[6], math.random(0, 63), math.random(0, 63)) end)
end
for i = 1, 5 do case("odd ellipse " .. i, 220, 170, function() gfx.setLineWidth(i); gfx.drawEllipseInRect(3, 3, 201 + 2 * i, 151 + 2 * i) end) end
for i = 1, 5 do case("centered ellipse " .. i, 120, 100, function() gfx.setStrokeLocation(gfx.kStrokeCentered); gfx.setLineWidth(2 + i); gfx.drawEllipseInRect(15, 12, 81 + i, 61 + i); gfx.setStrokeLocation(gfx.kStrokeInside) end) end
local src = gfx.image.new(32, 32); gfx.pushContext(src); gfx.fillRect(0, 0, 16, 16); gfx.fillCircleAtPoint(24, 24, 7); gfx.popContext()
for i = 1, 4 do case("drawSampled tilt " .. i, 80, 60, function() src:drawSampled(0, 0, 80, 60, 0.5, 0.5, 0.05 + 0.01 * i, 0.01, -0.01 * i, 0.06, 0.1 * i, 0.2, 40 + 10 * i, 20 * i, true) end) end
-- collision world after removeAll
local s = gfx.sprite.new(); s:setSize(20, 20); s:moveTo(50, 50); s:setCollideRect(0, 0, 20, 20); s:add()
local t = gfx.sprite.new(); t:setSize(20, 20); t:moveTo(52, 52); t:setCollideRect(0, 0, 20, 20)
out:write("query before\t" .. #gfx.sprite.querySpritesAtPoint(55, 55) .. "\n")
gfx.sprite.removeAll()
out:write("query after removeAll\t" .. #gfx.sprite.querySpritesAtPoint(55, 55) .. "\n")
t:add()
out:write("query after add t\t" .. #gfx.sprite.querySpritesAtPoint(55, 55) .. "\n")
out:close()
function playdate.update() end
