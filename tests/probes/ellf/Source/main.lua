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
local strokes = { f = gfx.kStrokeCentered, c = gfx.kStrokeCentered, i = gfx.kStrokeInside, o = gfx.kStrokeOutside }
local sizes = { {40, 40}, {41, 41}, {37, 23}, {30, 45}, {20, 21}, {11, 11}, {50, 31}, {8, 5}, {13, 6}, {60, 20}, {3, 9} }
for _, sk in ipairs({"f", "c"}) do
  for _, sz in ipairs(sizes) do
    for _, w in ipairs({1}) do
      img:clear(gfx.kColorWhite); gfx.pushContext(img); gfx.setColor(gfx.kColorBlack)
      gfx.setStrokeLocation(strokes[sk]); gfx.setLineWidth(w)
      if sk == "f" then gfx.fillEllipseInRect(15, 14, sz[1], sz[2]) else gfx.drawEllipseInRect(15, 14, sz[1], sz[2]) end
      gfx.popContext(); dump(string.format("%s_%dx%d_w%d", sk, sz[1], sz[2], w))
    end
  end
end
local fh = playdate.file.open("ellf.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
