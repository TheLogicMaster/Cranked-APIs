-- Probe: image:rotatedImage(angle) sizes and pixels for several images and angles.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local a = gfx.image.new(6, 14, gfx.kColorWhite)
gfx.pushContext(a); gfx.setColor(gfx.kColorBlack); gfx.fillRect(1, 0, 4, 14); gfx.fillRect(0, 10, 6, 4); gfx.popContext()
local b = gfx.image.new(9, 5, gfx.kColorBlack)
local c = gfx.image.new(10, 10, gfx.kColorClear)
gfx.pushContext(c); gfx.setColor(gfx.kColorBlack); gfx.drawLine(0, 0, 9, 9); gfx.drawRect(0, 0, 10, 10); gfx.popContext()
local out = {}
for _, im in ipairs({ { "a6x14", a }, { "b9x5", b }, { "c10x10", c } }) do
  for _, ang in ipairs({ 30, 45, -20, 60, 10, 135, 200, -100, 17, 33.3, 290, 340, 1, -1, 89, 91 }) do
    local r = im[2]:rotatedImage(ang); local w, h = r:getSize()
    local rows = {}
    for y = 0, h - 1 do local t = {}; for x = 0, w - 1 do local s = r:sample(x, y); t[#t + 1] = s == gfx.kColorBlack and "1" or (s == gfx.kColorWhite and "0" or "x") end; rows[#rows + 1] = table.concat(t) end
    out[#out + 1] = im[1] .. "_" .. ang .. "\t" .. w .. "x" .. h .. "\t" .. table.concat(rows, "/")
  end
end
local fh = playdate.file.open("rotimg.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
