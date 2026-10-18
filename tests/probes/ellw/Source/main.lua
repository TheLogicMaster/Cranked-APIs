-- Probe: wide ellipse outlines over widths, sizes (odd, even, non-square) and stroke locations.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local img = gfx.image.new(80, 80)
local function dump(name)
  local t = {}
  for y = 0, 79 do for x = 0, 79 do t[#t + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end end
  out[#out + 1] = name .. "|" .. table.concat(t)
end
local strokes = { c = gfx.kStrokeCentered, i = gfx.kStrokeInside, o = gfx.kStrokeOutside }
local sizes = { {40, 40}, {41, 41}, {37, 23}, {30, 45}, {20, 21}, {11, 11}, {50, 31} }
for _, sk in ipairs({"c", "i", "o"}) do
  for _, sz in ipairs(sizes) do
    for _, w in ipairs({2, 3, 4, 5, 6, 8}) do
      img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack)
      gfx.setStrokeLocation(strokes[sk]); gfx.setLineWidth(w)
      gfx.drawEllipseInRect(15, 14, sz[1], sz[2])
      gfx.popContext(); dump(string.format("%s_%dx%d_w%d", sk, sz[1], sz[2], w))
    end
  end
end
local fh = playdate.file.open("ellw.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
