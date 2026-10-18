local gfx = playdate.graphics
local geom = playdate.geometry
local out = {}
local function dump(img) local w, h = img:getSize(); local rows = {}; for y = 0, h - 1 do local b = {}; for x = 0, w - 1 do local s = img:sample(x, y); b[#b + 1] = s == gfx.kColorWhite and "1" or (s == gfx.kColorBlack and "0" or "x") end; rows[#rows + 1] = table.concat(b) end; return w .. "x" .. h .. ":" .. table.concat(rows, "/") end
local src = gfx.image.new("assets/img10x6")
local xforms = {
    { "rot90", function(t) t:rotate(90) end }, { "rot45", function(t) t:rotate(45) end }, { "rot30", function(t) t:rotate(30) end },
    { "rot180", function(t) t:rotate(180) end }, { "scale2", function(t) t:scale(2) end }, { "scale1.5", function(t) t:scale(1.5) end },
    { "scale0.5", function(t) t:scale(0.5) end }, { "scale2x1", function(t) t:scale(2, 1) end }, { "skew", function(t) t:skew(0.5, 0) end },
    { "translate3,2", function(t) t:translate(3, 2) end }, { "scale2+translate4,4", function(t) t:scale(2); t:translate(4, 4) end },
    { "rot90+scale2", function(t) t:rotate(90); t:scale(2) end },
}
for _, x in ipairs(xforms) do
    local t = geom.affineTransform.new(); x[2](t)
    out[#out + 1] = "T " .. x[1] .. "\t" .. dump(src:transformedImage(t))
    local img = gfx.image.new(40, 40, gfx.kColorWhite); gfx.pushContext(img); src:drawWithTransform(t, 20, 20); gfx.popContext()
    out[#out + 1] = "D " .. x[1] .. "\t" .. dump(img)
end
local f = playdate.file.open("xf.txt", playdate.file.kFileWrite); f:write(table.concat(out, "\n") .. "\n"); f:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
