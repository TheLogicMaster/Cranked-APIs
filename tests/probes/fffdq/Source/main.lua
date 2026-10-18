-- Probe: getTextSize and drawText widths around the replacement glyph U+FFFD in styled system text
import "CoreLibs/graphics"
local gfx = playdate.graphics
local fh = playdate.file.open("out.txt", playdate.file.kFileWrite)
local R = "\u{FFFD}"
local cases = {R, "a" .. R, R .. "a", R .. R, "_" .. R .. "_", "_a" .. R .. "_", "_" .. R .. "a_", "_" .. R .. R .. "_",
  "*" .. R .. "*", "*a" .. R .. "*", "*" .. R .. "a*", "_" .. R .. "_a", "a_" .. R .. "_", "_ " .. R .. "_", "_" .. R .. " _",
  "_\u{2603}_", "\u{2603}", "_a_", "_ab_", "_" .. R .. "_\n_" .. R .. "_", "_" .. R .. "_\na"}
for i, t in ipairs(cases) do
  local img = gfx.image.new(80, 60, gfx.kColorWhite)
  gfx.pushContext(img)
  local w, h = gfx.drawText(t, 0, 0)
  gfx.popContext()
  local tw, th = gfx.getTextSize(t)
  local minx, maxx = 99, -1
  for y = 0, 59 do for x = 0, 79 do if img:sample(x, y) == gfx.kColorBlack then if x < minx then minx = x end if x > maxx then maxx = x end end end end
  fh:write(i .. " draw=" .. w .. "x" .. h .. " size=" .. tw .. "x" .. th .. " ink=" .. minx .. "-" .. maxx .. "\n")
end
fh:close()
function playdate.update() end
