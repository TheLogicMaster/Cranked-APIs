-- Huge-scale rotated drawing (the visible part only is sampled above 4 MP). Prints a row-hash per case
-- so a build can be compared with an earlier one.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = playdate.file.open("out.txt", playdate.file.kFileWrite)
local src = gfx.image.new(5, 3, gfx.kColorWhite)
gfx.pushContext(src); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 0, 2, 1); gfx.fillRect(3, 1, 2, 2); gfx.drawPixel(2, 2); gfx.popContext()
local cases = { {200, 120, 30, 450, 450}, {200, 120, 47, 700, 380}, {-300, 500, 13, 400, 420}, {200, 120, 75, 330, 300}, {50, 60, 211, 410, 380} }
for i, c in ipairs(cases) do
    local dst = gfx.image.new(400, 240, gfx.kColorClear)
    gfx.pushContext(dst); gfx.setDrawOffset(i * 7 - 20, i * 3 - 9); src:drawRotated(c[1], c[2], c[3], c[4], c[5]); gfx.popContext()
    local h = 0
    for y = 0, 239 do for x = 0, 399 do local p = dst:sample(x, y); h = (h * 31 + p + 1) % 1000000007 end end
    out:write(i .. " " .. h .. "\n")
end
out:close()
function playdate.update() end
