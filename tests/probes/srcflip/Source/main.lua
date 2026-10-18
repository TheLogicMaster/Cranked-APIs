-- Probe: image:draw with a source rect that runs past the image, under every flip, on white and black
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local small = gfx.image.new(13, 9, gfx.kColorClear)
gfx.pushContext(small) gfx.setColor(gfx.kColorBlack) gfx.fillCircleAtPoint(6, 4, 4) gfx.setColor(gfx.kColorWhite) gfx.drawLine(0, 0, 12, 8) gfx.popContext()
local opaque = gfx.image.new(13, 9, gfx.kColorWhite)
gfx.pushContext(opaque) gfx.setColor(gfx.kColorBlack) gfx.fillRect(0, 0, 4, 9) gfx.drawLine(0, 8, 12, 0) gfx.popContext()
local flips = { gfx.kImageUnflipped, gfx.kImageFlippedX, gfx.kImageFlippedY, gfx.kImageFlippedXY }
local rects = { { 0, 5, 11, 10 }, { 0, 0, 13, 9 }, { 3, 2, 20, 4 }, { -2, -3, 8, 8 }, { 10, 6, 6, 6 }, { 5, 0, 4, 20 } }
for _, bg in ipairs({ gfx.kColorWhite, gfx.kColorBlack }) do
  for ii, im in ipairs({ small, opaque }) do
    for _, fl in ipairs(flips) do
      for ri, r in ipairs(rects) do
        local t = gfx.image.new(40, 30, bg)
        gfx.pushContext(t) im:draw(8, 6, fl, r[1], r[2], r[3], r[4]) gfx.popContext()
        local s = {}
        for y = 0, 29 do local row = {} for x = 0, 39 do local c = t:sample(x, y) row[#row + 1] = c == gfx.kColorBlack and "#" or "." end s[#s + 1] = table.concat(row) end
        fh:write(string.format("bg%d img%d flip%d rect%d\n%s\n", bg, ii, fl, ri, table.concat(s, "\n")))
      end
    end
  end
end
fh:close()
function playdate.update() end
