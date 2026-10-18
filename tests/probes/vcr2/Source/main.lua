-- 40 consecutive vcrPauseFilterImage calls on a 400x240 pattern (pins the noise-row boundaries)
local gfx = playdate.graphics
local f = playdate.file.open("out.txt", playdate.file.kFileWrite)
local function dump(img)
    local w, h = img:getSize()
    local rows = {}
    for y = 0, h - 1 do
        local r = {}
        for x = 0, w - 1 do local c = img:sample(x, y); r[#r + 1] = c == gfx.kColorBlack and "0" or (c == gfx.kColorWhite and "1" or "x") end
        rows[#rows + 1] = table.concat(r)
    end
    return w .. "x" .. h .. ":" .. table.concat(rows, "/")
end
local src = gfx.image.new(400, 240, gfx.kColorWhite)
gfx.pushContext(src); gfx.setColor(gfx.kColorBlack)
for i = 0, 640, 9 do gfx.drawLine(i, 0, i - 240, 240) end
gfx.popContext()
f:write("src1\t" .. dump(src) .. "\n")
for i = 1, 40 do
    local out = src:vcrPauseFilterImage()
    f:write("case" .. i .. "\t" .. dump(out) .. "\n"); f:flush()
end
f:close()
playdate.stop()
function playdate.update() end
