-- Probe: drawWithTransform against drawSampled with equivalent parameters
local gfx = playdate.graphics
local geom = playdate.geometry
local f = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function dump(img)
    local w, h = img:getSize(); local rows = {}
    for y = 0, h - 1 do local r = {} for x = 0, w - 1 do r[#r + 1] = img:sample(x, y) == gfx.kColorBlack and "0" or "1" end rows[#rows + 1] = table.concat(r) end
    return table.concat(rows, "/")
end
local function D(name, fn)
    local img = gfx.image.new(40, 40, gfx.kColorWhite)
    gfx.pushContext(img); fn(); gfx.popContext()
    f:write(name .. "\t" .. dump(img) .. "\n"); f:flush()
end
local src = gfx.image.new(4, 3, gfx.kColorBlack)
local src2 = gfx.image.new(5, 4, gfx.kColorWhite)
gfx.pushContext(src2); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 2, 2); gfx.drawPixel(4, 3); gfx.drawPixel(3, 0); gfx.popContext()
D("dwt scale2", function() local t = geom.affineTransform.new(); t:scale(2); t:translate(4, 4); src:drawWithTransform(t, 2, 2) end)
D("ds scale2", function() src:drawSampled(2, 3, 8, 6, 0.5, 0.5, 0.5, 0, 0, 0.5, 0.5, 0.5, 1, 0, false) end)
D("dwt id", function() local t = geom.affineTransform.new(); src2:drawWithTransform(t, 10, 10) end)
D("dwt id frac", function() local t = geom.affineTransform.new(); src2:drawWithTransform(t, 10.5, 10.25) end)
D("dwt scale3", function() local t = geom.affineTransform.new(); t:scale(3, 2); src2:drawWithTransform(t, 20, 20) end)
D("dwt rot30", function() local t = geom.affineTransform.new(); t:rotate(30); t:scale(2); src2:drawWithTransform(t, 20, 20) end)
D("dwt rot90", function() local t = geom.affineTransform.new(); t:rotate(90); src2:drawWithTransform(t, 20, 20) end)
D("dwt shear", function() local t = geom.affineTransform.new(); t:skew(30, 0); t:scale(2); src2:drawWithTransform(t, 20, 20) end)
D("dwt flip", function() local t = geom.affineTransform.new(); t:scale(-2, 1.5); t:translate(1.5, -2); src2:drawWithTransform(t, 20, 20) end)
D("dwt small", function() local t = geom.affineTransform.new(); t:scale(0.5); src2:drawWithTransform(t, 20, 20) end)
f:close()
playdate.stop()
function playdate.update() end
