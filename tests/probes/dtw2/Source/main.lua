-- Probe: the size gfx.drawText returns when the first glyphs have no ink or start right of the origin
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local R = "\u{FFFD}"
local cases = {" a", "  a", "a", ".a", "'a", "^", "_^_", "j", "_j_", "\na", "\n\na", " \na", "a\n", "_" .. R .. "_\na",
  "_" .. R .. "_ a", "_l_", "_l_a", "a_l_", "_" .. R .. "a_", "_a" .. R .. "_", "  ", "_" .. R .. "_\n_" .. R .. "_\nb", ",", "-", "_-_"}
for i, t in ipairs(cases) do
  local img = gfx.image.new(80, 70, gfx.kColorWhite)
  gfx.pushContext(img)
  local w, h = gfx.drawText(t, 0, 0)
  gfx.popContext()
  local x0, x1, y0, y1 = 99, -1, 99, -1
  for y = 0, 69 do for x = 0, 79 do if img:sample(x, y) == gfx.kColorBlack then
    x0 = math.min(x0, x) x1 = math.max(x1, x) y0 = math.min(y0, y) y1 = math.max(y1, y) end end end
  fh:write(i .. " [" .. t:gsub(R, "R"):gsub("\n", "/") .. "] draw=" .. w .. "x" .. h .. " ink=" .. x0 .. "-" .. x1 .. "," .. y0 .. "-" .. y1 .. "\n")
end
fh:close()
function playdate.update() end
