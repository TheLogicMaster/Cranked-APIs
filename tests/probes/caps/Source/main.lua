-- Probe: round and square line caps on vertical, horizontal, and diagonal lines, integer and fractional widths.
import "CoreLibs/graphics"
local gfx = playdate.graphics
local out = {}
local function dump(name, fn)
  local img = gfx.image.new(40, 60, gfx.kColorWhite)
  gfx.pushContext(img); gfx.setColor(gfx.kColorBlack); fn(); gfx.popContext()
  local rows = {}
  for y = 0, 59 do local r = {}; for x = 0, 39 do r[#r + 1] = img:sample(x, y) == gfx.kColorBlack and "1" or "0" end; rows[#rows + 1] = table.concat(r) end
  out[#out + 1] = name .. "\t" .. table.concat(rows, "/")
end
local widths = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 9.3, 9.5, 9.7, 8.6, 7.2, 4.4, 2.5, 1.5 }
for _, cap in ipairs({ { "round", gfx.kLineCapStyleRound }, { "square", gfx.kLineCapStyleSquare }, { "butt", gfx.kLineCapStyleButt } }) do
  for _, w in ipairs(widths) do
    dump(cap[1] .. "_v_" .. w, function() gfx.setLineCapStyle(cap[2]); gfx.setLineWidth(w); gfx.drawLine(20, 15, 20, 45) end)
    dump(cap[1] .. "_h_" .. w, function() gfx.setLineCapStyle(cap[2]); gfx.setLineWidth(w); gfx.drawLine(8, 30, 32, 30) end)
    dump(cap[1] .. "_d_" .. w, function() gfx.setLineCapStyle(cap[2]); gfx.setLineWidth(w); gfx.drawLine(10, 18, 28, 42) end)
  end
end
local fh = playdate.file.open("caps.txt", playdate.file.kFileWrite); fh:write(table.concat(out, "\n") .. "\n"); fh:close()
if playdate.simulator then playdate.simulator.exit() end
playdate.stop()
